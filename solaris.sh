#!/bin/bash
# IFS=$'\n'       # make newlines the only separator

RED='\033[0;31m'
NC='\033[0m' # No Color
#echo -e "${RED}love${NC} Solaris"
cptlog(){
  # $1 motif $2 file
  #da=`date +%b\ %d`
  # nberror=`egrep -i $i $2 | egrep -c "${da}"`
  nberror=`egrep -ic $i $2`
  echo $nberror
}

echo "#Socle `hostname` `who -b | tr -s ' '` - `prtconf -b | grep ORCL | awk '{print $2}'` - `date`";
if [ -f /var/adm/sa/sa`date +%d` ]; # test if sarfile of the say exist
then
   [ `sar -u | grep Average | awk '{print $5}'` -le 40 ] && echo "x CPU Server `hostname` surcharge"
fi

lsvmstat=`vmstat 1 2 | tail -1`
a=1
swapuser=`swap -s | awk '{print $9}' | sed s"/k//"`
swapavaiable=`swap -s | awk '{print $11}' | sed s"/k//"`
swaptotal=$(echo "$swapuser" "+" "$swapavaiable" | bc)
# echo "=> Swap total : $swaptotal kb"
for i in $lsvmstat
do
	# echo "=D $i"
	case $a in
	1) #Nombre de threads de noyau dans la file d'attente de répartition
	[ $i -ge 50 ] && echo "x Nb thread too high ( $i )"
	;;
	2) # Nombre de threads de noyau bloqués qui sont en attente de ressources
	[ $i -ge 50 ] && echo "x Nb thread bloque too high ( $i ) "
	;;
	3) #Nombre de LWP extraits du swap qui attendent la fin du traitement des ressources
	[ $i -ge 50 ] && echo "x Nb Nombre de LWP extraits du swap too high ( $i ) "
	;;
	4) # Espace de swap disponible
	echo "* (`echo "scale=2; (${swapavaiable}/${swaptotal})*100" | bc` % swap dispo )   $i Kb swap disponible sur $swaptotal kb"
  # echo "`echo "scale=2; (${swapavaiable}/${swaptotal})*100" | bc` % swap dispo"

	;;
	5) # Taille de la liste d'espaces libres
	b=$(/usr/sbin/prtconf | /usr/bin/awk '/Memory/ {print $3*1024}');
	m=$(vmstat 1 2 | tail -1 | awk "{print (\$5/$b)*100}")
	[ ${m%.*} -le 15 ] && echo "x Memoire libre critique ( $m ) % libre" || echo "* $m % memoire libre "
	;;
	6) #Pages récupérées
	pagerecup=$i
	;;
	7) # Erreurs mineures et majeures
	errpagemin=$i
	if [[ $i -gt 39 ]]; then
		echo "x erreurs Pages ( $i )"
	fi
  ;;
	17) # Interruptions par seconde
	if [[ $i -gt 200 ]]; then
		echo "x Interruptions par seconde ( $i )"
	fi
  ;;
	18) # Appels système par seconde
	if [[ $i -gt 200 ]]; then
		echo "x Appels system par seconde ( $i )"
	fi
	;;
	19) # Taux de changement de contexte CPU
	if [[ $i -gt 200 ]]; then
		echo "x Taux de changement de contexte CPU ( $i )"
	fi
	;;
	20) # Temps utilisateur
	if [[ $i -gt 50 ]]; then
		echo "x Temps cpu user trop eleve ( $i )"
	fi
	;;
	21) # Temps système
	if [[ $i -gt 50 ]]; then
		echo "x Temps cpu systeme trop eleve ( $i )"
	fi
	;;
	22) # Temps d'inactivité
	if [[ $i -lt 20 ]]; then
		echo "x Server surcharge ( $i % idle)"
	fi
	;;
	esac
	a=$((a+1))
done

# materiel
[ `fmadm faulty | wc -l` -gt 0 ] && echo "x Erreur materiel potentiel ! (please run fmadm faulty)" && fmadm faulty | grep "Fault class"  | sort -u

[ `prtdiag -v | grep -ic fail` -gt 0 ] && echo "x Erreur Materiel "
prtdiag -v | grep -i fail
# IO error
diskerro=0
[ `iostat -en | egrep -v "error|device" | awk '{ if ($4 > 30 )print $4, " = ", $5}' | wc -l ` -ge 1 ] && diskerro=1 && echo "x Error disk"
[ $diskerro -eq 1 ] && iostat -en | egrep -v "error|device" | awk '{ if ($4 > 30 )print " ",$4, " = ", $5}' | sort -nr


# close Waiting
[ `netstat -an | grep -c CLOSE_WAIT` -ge 2 ] && echo "X Presence de `netstat -an | grep -c CLOSE_WAIT` Clos_wait" || echo "Pas de CLOSE_WAIT"

# IO saturation
for i in `iostat -xpn 1 2 | grep -v extended | awk '{ if ($10 > 60) print $10, " = ",$11}' | sort -nr`
do
  echo "x Saturation disk : $i"
done

# FS
fs=`df -h | grep -v "Filesystem" | egrep -c "([89][0-9]+%)|(100)%|size"`
[ $fs -ge 1 ] && echo "x $fs File system sature" && df -h | grep -v "Filesystem" | egrep  "([89][0-9]+%)|(100)%|size"

# service
# svcs -x

# Ingres
pingr=`ps -ef | grep -v grep | grep -ic ingr`
if [[ $pingr -ge 1 ]]; then
  for proc in {"gcc","iigcd","dmfacp","dmfrcp"}
    do
      echo -ne " `ps -ef | grep -v grep | grep -i ingr | egrep -ic ${proc}` process ${proc} | "
    done
fi


#Zombie
pzz=`ps -ef | grep -v grep | grep -ci defun`
[ $pzz -ge 1 ] && echo -ne "x $pzz process zombies : " || echo "* Pas de proc zombie"
for i in `ps -ef | grep -v grep | grep -i defun | awk '{print $2}'`;do echo -ne "$i | ";done
echo ""
# vip
viphost=`grep -ic vip /etc/hosts`
[ ${viphost} -ge 1 ] && echo "${viphost} servers Cluster"

# Oracle
pora=`ps -ef | grep -v grep | egrep -ic oracle`
if [ ${pora} -ge 1 ];then
  echo -ne "${pora} proc Oracle | `ps -ef | egrep -i oracle | grep -v grep | egrep -ic ora_pmon` proc pmon | `ps -ef | egrep -i "oracle|grid" | egrep -i LISTENER | egrep -vic scan` proc Listener | `ps -ef | egrep -i "oracle|grid" | egrep -i LISTENER | egrep -ic scan` Listener SCAN"
fi
echo ""
# HBA
hba=`fcinfo  hba-port | egrep -c "HBA Port"`
[ $hba -ge 1 ] && echo -ne "${hba} cartes HBA , `fcinfo  hba-port | egrep -ic online` Carte Online, `fcinfo  hba-port | egrep -ic offline` Carte Offline | `luxadm -e port | grep -ic 'CONNECTED' ` pci connected"
echo ""
for ct in `fcinfo  hba-port | egrep "HBA Port" | cut -d ":" -f 2`
do
  hbaerr=`fcinfo  hba-port $ct | egrep -c offline`
  [ ${hbaerr} -ge 1 ] && echo "$ct `fcinfo  hba-port $ct | egrep offline` "
done
# echo "`luxadm -e port | grep -ic 'CONNECTED' ` pci connected"

[ /sbin/zpool ] && zp=`zpool list | grep -vc NAME`
[ /sbin/zpool ] && zpool status -xv
[ ${zp} -ge 2 ] && echo -ne "${zp} pool zfs,`zpool list | grep -v NAME | grep -vc ONLINE` offline/degrade"
if [[ ${zp} -ge 1 ]]; then
  zpe=`zpool list | grep -v NAME | egrep -vc ONLINE`
  if [[ ${zpe} -ge 1 ]]; then
    echo "x Pool offline"
    zpool list | grep -v ONLINE
  fi
fi
echo ""
logerr=0
for file in {"/var/log/syslog","/var/log/secure","/var/log/messages","/var/adm/messages"}
do
  for i in {"failed","error","erreur","warning","ban ","denied","kernel"}
  do
    [ -f $file ] && ero="$(cptlog $i $file)"
    [ "$ero" != '0' ] && echo -ne " $ero $i dans $file | " && logerr=$((logerr+1))
    ero='0'
  done
done
[[ $logerr -eq 0 ]] && echo "* Aucune erreurs dans les fichier de log"
echo ""

# modular debugger:
#  echo "::memstat" | mdb -k

mdb=`echo "::memstat" | mdb -k | egrep '[5-9][0-9]\%'`
if [[ `echo ${mdb} | wc -l` -ge 1 ]];then
  echo "x Mem stat :"
  echo $mdb
fi

# nb file open by process
# pfiles 29803 | nawk '/[0-9]: /{a++}END{print a}' WIP
# proc cpu gourmand
echo "* Processus utilisant le plus de CPU:"
prstat -s cpu -Z 1 1 | grep -v PID | head -2

# proc ram gourmand
echo "* Processus utilisant le plus de RAM:"
prstat -s rss -Z 1 1 | grep -v PID | head -2
# prstat -s rss -n 2 -Z 1 1 | grep -v Total

# check tmp
dftmp=`df -h /tmp | egrep "([5-9][0-9]+%)|(100)\%"`
if [[ -n ${dftmp} ]]; then
  echo "x Partition /tmp à + de 50%"
  df -h /tmp
fi

# Swap usage
echo "* Processus utilisant le swap"
for i in /proc/*; do
 SWAP=`pmap -S $i 2> /dev/null | grep ^total | awk '{ print $3; }'`
 [ "xx$SWAP" != "xx" ] && echo "$(($SWAP/1024)) Mbytes -> Proc $i"
done | sort -n | tail -2


#error metadevice ( WIP )
#if [ -f /usr/sbin/metastat ] && /usr/sbin/metastat 2>/dev/null | egrep -i "resync|maint" > $out && [ -s $out ]; then
