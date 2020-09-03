#!/bin/bash
# IFS=$'\n'       # make newlines the only separator
OLDIFS=$IFS # backup orginal $IFS var
RED='\033[0;31m' # some color
GREEN='\033[0;32m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color
#echo -e "${RED}love${NC} Solaris" # example

# Array of commands
cmd=()
cmd+=("ssh root@`hostname`")

# diag phrase
diag="# Le server `hostname` "

server="root@`hostname`:>"
cptlog(){ # $1 keyword to search for # $2 logfile to search in
  # $1 motif $2 file
  #da=`date +%b\ %d`
  # nberror=`egrep -i $i $2 | egrep -c "${da}"`
  nberror=`egrep -ic $i $2`
  echo $nberror
}

displaybar(){ #$1 pourcentage # $2 text % # $3 size ( ex 20)
inred=`echo "scale=0; ($3*$1/100)" | bc`
inred=$(($inred-1))
i=0

echo -n "["
while [[ $i -lt ${inred} ]]; do
    echo -ne "${BLUE}|"
    i=$(($i+1))
done
echo -ne "${RED}|"
i=0
goal=$(($3-${inred}))
while [[ i -lt ${goal} ]]; do
    echo -en "${NC} "
    i=$(($i+1))
done
echo -n "]"
echo -ne " $1 % $2"
echo ""

}

echo "#Socle `hostname` `who -b | tr -s ' '` - `prtconf -b | grep ORCL | awk '{print $2}'` - `date`";
if [ -f /var/adm/sa/sa`date +%d` ]; # test if sarfile of the say exist
then
   [ `sar -u | grep Average | awk '{print $5}'` -le 40 ] && echo "x CPU Server `hostname` surcharge"
fi

up=`uptime`
if [[ `echo $up | grep -ic day` ]]; then
  #day in uptime
  day=`echo $up | awk '{print $3}'`
  if [[ $day -gt 100 ]]; then
    diag="${diag}, a un uptime eleve, (${day} jours) "
  fi
fi
# idle

idle=`iostat -c | egrep "[0-9]" | awk '{print$4}'`
# Make phrase idle
if [[ ${idle} -lt 30 ]]; then
  diag="${diag} est surcharge au niveau CPU (${idle}% idle), "
else
  diag="${diag} n'est pas surcharge au niveau CPU (${idle}% idle), "
fi
displaybar $idle " % idle " 30
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
	[ $i -ge 70 ] && echo -e "x Nb thread too high ( ${RED}$i${NC} )"
	;;
	2) # Nombre de threads de noyau bloqués qui sont en attente de ressources
	[ $i -ge 1500 ] && echo -e "x Nb thread bloque too high ( ${RED}$i${NC} ) "
	;;
	3) #Nombre de LWP extraits du swap qui attendent la fin du traitement des ressources
	[ $i -ge 1500 ] && echo -e "x Nb Nombre de LWP extraits du swap too high ( ${RED}$i${NC} ) "
	;;
	4) # Espace de swap disponible
  swapdispo=`echo "scale=2; (${swapavaiable}/${swaptotal})*100" | bc`
	echo "* ($swapdispo % swap dispo )   $i Kb swap disponible sur $swaptotal kb"
  displaybar $swapdispo "swap dispo" 30
  swapd=$( printf "%.0f" $swapdispo)
  if [[ ${swapd} -lt 40  ]]; then
    usage="fortement"
  else
    usage="faiblement"
  fi
  diag="${diag} le swap est ${usage} solicite, seul ${swapd} % est disponible,"
	;;
	5) # Taille de la liste d'espaces libres
	b=$(/usr/sbin/prtconf | /usr/bin/awk '/Memory/ {print $3*1024}');
	m=$(vmstat 1 2 | tail -1 | awk "{print (\$5/$b)*100}")
	if [[ ${m%.*} -le 30 ]];then
    echo "x Memoire libre critique ( $m ) % libre ($(($b/1024)) total)"
    usage="fortement"
  else
    echo "* $m % memoire libre ($(($b/1024)) total)"
    usage="faiblement"
  fi
  diag="${diag} la memoire ram est ${usage} utilisee, ${m} % de ram est disponible."
  displaybar $m "ram dispo" 30
	;;
	6) #Pages récupérées
	pagerecup=$i
	;;
	7) # Erreurs mineures et majeures
	errpagemin=$i
	if [[ $i -gt 39 ]]; then
		echo -e "x erreurs Pages ( ${RED}$i${NC} )"
	fi
  ;;
	17) # Interruptions par seconde
	if [[ $i -gt 200 ]]; then
		echo -e "x Interruptions par seconde ( ${RED}$i${NC} )"
	fi
  ;;
	18) # Appels système par seconde
	if [[ $i -gt 200 ]]; then
		echo -e "x Appels system par seconde ( ${RED}$i${NC} )"
	fi
	;;
	19) # Taux de changement de contexte CPU
	if [[ $i -gt 200 ]]; then
		echo -e "x Taux de changement de contexte CPU ( ${RED}$i${NC} )"
	fi
	;;
	20) # Temps utilisateur
	if [[ $i -gt 50 ]]; then
		echo -e "x Temps cpu user trop eleve ( ${RED}$i${NC} )"
	fi
	;;
	21) # Temps système
	if [[ $i -gt 50 ]]; then
		echo -e "x Temps cpu systeme trop eleve ( ${RED}$i${NC} )"
	fi
	;;
	22) # Temps d'inactivité
	if [[ $i -lt 20 ]]; then
		echo -e "x Server surcharge ( ${RED}$i${NC} % idle)"
    displaybar $i " % idle" 30
	fi
	;;
	esac
	a=$((a+1))
done

# materiel
mat=`fmadm faulty | wc -l`
if [[ ${mat} -gt 0 ]];then
   echo "x Erreur materiel potentiel ! (please run fmadm faulty)" && fmadm faulty | grep "Fault class"  | sort -u
   diag="$diag, Une erreur materiel sur le server `hostname`"
 else
   diag="$diag, Pas d'erreur materiel sur le server `hostname`"
fi
[ `prtdiag -v | grep -c "No failures found"` -eq 0 ] && echo -e "${GREEN}Pas d'erreur materiel${NC}"
prtdiag -v | grep "No failures found"
# IO error
diskerro=0
[ `iostat -en | egrep -v "error|device" | awk '{ if ($4 > 30 )print $4, " = ", $5}' | wc -l ` -ge 1 ] && diskerro=1 && echo "x Error disk" && echo "${server} iostat -en"
if [[ $diskerro -eq 1 ]];then
  iostat -en | egrep -v "error|device" | awk '{ if ($4 > 30 )print " ",$4, " = ", $5}' | sort -nr
  diag="$diag, plusieurs erreur disk sont presentes"
fi

# close Waiting
[ `netstat -an | grep -c CLOSE_WAIT` -ge 2 ] && echo -e "X Presence de ${RED}`netstat -an | grep -c CLOSE_WAIT`${NC} Clos_wait" || echo -e "* Pas de connexion ${GREEN}CLOSE_WAIT${NC}"

# IO saturation
for i in `iostat -xpn 1 2 | grep -v extended | awk '{ if ($10 > 60) print $10, " = ",$11}' | sort -nr`
do
  echo "x Saturation disk : $i"
  diag="$diag, certain disk sont sature d'I/O."
done

# FS
fs=`df -h | grep -v "Filesystem" | egrep -c "([89][0-9]+%)|(100)%|size"`
if [ $fs -ge 1 ];then
  echo -e "x ${BLUE}$fs${NC} File system sature" && df -h | grep -v "Filesystem" | egrep  "([89][0-9]+%)|(100)%|size"
  diag="$diag ${fs} File system occupe(s) a plus de 80%."
fi
# service
# svcs -x

# Ingres
pingr=`ps -ef | grep -v grep | grep -ic ingr`
if [[ $pingr -ge 1 ]]; then
  for proc in {"gcc","iigcd","dmfacp","dmfrcp"}
    do
      echo -ne " ${BLUE}`ps -ef | grep -v grep | grep -i ingr | egrep -ic ${proc}`${NC} process ${proc} | "
    done
    echo ""
fi


#Zombie
pzz=`ps -ef | grep -v grep | grep -ci defun`

if [[ $pzz -ge 1 ]]; then
  echo -ne "x ${RED}$pzz${NC} process zombies : "
  for i in `ps -ef | grep -v grep | grep -i defun | awk '{print $2}'`;do echo -ne "$i | ";done
  diag="${diag} le server `hostname` a ${pzz} processus zombie(s)."
  echo ""
  cmd+=('ps -ef | grep -v grep | grep -i defun')
else
  echo -e "* Pas de proc ${GREEN}zombie${NC}"
  diag="${diag} le server `hostname` n'as pas processus zombie."
fi


# vip
viphost=`grep -ic vip /etc/hosts`
if [ ${viphost} -ge 1 ];then
  echo "${viphost} servers Cluster"
  cmd+=('egrep -i vip /etc/hosts')
  diag="${diag} , nota : Cluster a ${viphost} noeuds"
fi
# Oracle
pora=`ps -ef | grep -v grep | egrep -ic oracle`
if [ ${pora} -ge 1 ];then
  echo -ne "${BLUE}${pora}${NC} proc Oracle | ${BLUE}`ps -ef | egrep -i oracle | grep -v grep | egrep -ic ora_pmon`${NC} proc pmon | ${BLUE}`ps -ef | egrep -i "oracle|grid" | egrep -i LISTENER | egrep -vic scan`${NC} proc Listener | ${BLUE}`ps -ef | egrep -i "oracle|grid" | egrep -i LISTENER | egrep -ic scan`${NC} Listener SCAN"
  echo ""
  cmd+=('ps -ef | egrep -i oracle | grep -v grep | egrep -i ora_pmon')
fi
# HBA
hba=`fcinfo  hba-port | egrep -c "HBA Port"`
if [[ $hba -ge 1 ]]; then
  echo -ne "${BLUE}${hba}${NC} cartes HBA , ${BLUE}`fcinfo  hba-port | egrep -ic online`${NC} Carte Online, ${BLUE}`fcinfo  hba-port | egrep -ic offline`${NC} Carte Offline | ${BLUE}`luxadm -e port | grep -ic 'CONNECTED'`${NC} pci connected"
  echo ""
fi
for ct in `fcinfo  hba-port | egrep "HBA Port" | cut -d ":" -f 2`
do
  hbaerr=`fcinfo  hba-port $ct | egrep -c offline`
  [ ${hbaerr} -ge 1 ] && echo -e "${BLUE}${ct}${NC} `fcinfo  hba-port $ct | egrep offline` "
  cmd+=('fcinfo  hba-port $ct | egrep offline')
done
# echo "`luxadm -e port | grep -ic 'CONNECTED' ` pci connected"


if [[ -e /sbin/zpool ]]; then
  zp=`zpool list | grep -vc NAME`
  zpool status -xv
  cmd+=('zpool status -xv')
fi
# [[ ${zp} -ge 1 ]] && echo -ne "${zp} pool zfs,`zpool list | grep -v NAME | grep -vc ONLINE` offline/degrade"
if [[ ${zp} -ge 1 ]]; then
  echo -ne "${BLUE}${zp}${NC} pool zfs,${BLUE}`zpool list | grep -v NAME | grep -vc ONLINE`${NC} offline/degrade"
  echo ""
  zpe=`zpool list | grep -v NAME | egrep -vc ONLINE`
  if [[ ${zpe} -ge 1 ]]; then
    echo "x Pool offline"
    zpool list | grep -v ONLINE
    echo ""
    diag="${diag} , le server `hostname` a ${zpe} pool ZFS en erreurs"
  fi
fi
logerr=0
for file in {"/var/log/syslog","/var/log/secure","/var/log/messages","/var/adm/messages"}
do
  for i in {"failed","error","erreur","warning","ban ","denied","kernel"}
  do
    [ -f $file ] && ero="$(cptlog $i $file)"
    if [ "$ero" != '0' ];then
       logerr=$((logerr+1))
       echo -e "egrep -i $i ${file} (${RED}${ero}${NC})${BLUE} `egrep -i $i ${file} | tail -1 | cut -d ' ' -f 1,3`${NC}"
     fi
    ero='0'
  done
done
if [[ $logerr -eq 0 ]];then
   echo "* Aucune erreurs dans les fichier de log"
   cmd+=("date && egrep -ic 'failed|error,kernel' /var/adm/messages")
   diag="${diag} , aucune erreur n'apparait dans les fichiers de log systeme"
 else
   echo ""
fi

# modular debugger:
#  echo "::memstat" | mdb -k

mdb=`echo "::memstat" | mdb -k | egrep '[5-9][0-9]\%'`
if [[ `echo ${mdb} | wc -l` -ge 1 ]];then
  echo "x Mem stat :"
  echo $mdb
  cmd+=('echo "::memstat" | mdb -k')
fi

# nb file open by process
# pfiles 29803 | nawk '/[0-9]: /{a++}END{print a}' WIP
# proc cpu gourmand
echo -e "* Processus utilisant le plus de ${BLUE}CPU ${NC}:"
prstat -s cpu -Z 1 1 | grep -v PID | head -2
IFS=$'\n'
cpupid="top -p `prstat -s cpu -Z 1 1 | grep -v PID | head -1 | awk '{print $1}'`"
cmd+=($cpupid)
IFS=$OLDIFS
# proc ram gourmand
echo -e "* Processus utilisant le plus de ${BLUE}RAM:${NC}"
prstat -s rss -Z 1 1 | grep -v PID | head -2
# prstat -s rss -n 2 -Z 1 1 | grep -v Total
IFS=$'\n'
rampid="top -p `prstat -s rss -Z 1 1 | grep -v PID | head -1 | awk '{print $1}'`"
cmd+=($rampid)
IFS=$OLDIFS

# check tmp
dftmp=`df -h /tmp | egrep "([5-9][0-9]+%)|(100)\%"`
if [[ -n ${dftmp} ]]; then
  echo -e "x ${RED}Partition /tmp${NC} a + de 50%"
  df -h /tmp
  cmd+=('df -h /tmp')
  diag="${diag} , attention le file system /tmp est utilise a plus de la moitie, celui etant utilise comme partition swap, cela peut provoquer des ralentissements"
fi

# Swap usage
echo -e "* Processus utilisant le ${BLUE}swap${NC}"
for i in /proc/*; do
 SWAP=`pmap -S $i 2> /dev/null | grep ^total | awk '{ print $3; }'`
 [ "xx$SWAP" != "xx" ] && echo -e "$(($SWAP/1024)) Mbytes -> Proc $i"
done | sort -n | tail -2


#error metadevice ( Work in progress )
#if [ -f /usr/sbin/metastat ] && /usr/sbin/metastat 2>/dev/null | egrep -i "resync|maint" > $out && [ -s $out ]; then

#set IFS to include var with space
# Display all cmd generate
IFS=$'\n'
for i in ${cmd[@]}
do
  echo $i
done

# Display commands df -h for Fiile system
if [ $fs -ge 1 ];then
  df -h | egrep  "([89][0-9]+%)|(100)%|size" | awk '{print "df -h",$NF}'
fi
IFS=$OLDIFS # reset to the original value $IFS

echo $diag
