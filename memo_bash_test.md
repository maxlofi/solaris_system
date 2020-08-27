# test bash

```

Tests sur les fichiers
Expression 	Code de retour
-b FILE 	Vrai si le fichier existe et est du type spécial bloc
-c FILE 	Vrai si le fichier existe et est du type spécial caractère
-d FILE 	Vrai si le fichier existe et est du type répertoire
-e FILE 	Vrai si le fichier existe
-f FILE 	Vrai si le fichier existe et est du type ordinaire
-G FILE 	Vrai si le fichier existe et si l'utilisateur appartient au groupe propriétaire du fichier
-h FILE 	Vrai si le fichier existe et est du type lien symbolique
-L FILE 	Vrai si le fichier existe et est du type lien symbolique (idem -h)
-O FILE 	Vrai si le fichier existe et si l'utilisateur est le propriétaire du fichier
-r FILE 	Vrai si le fichier existe et est accessible en lecture
-s FILE 	Vrai si le fichier existe et n'est pas vide
-S FILE 	Vrai si le fichier existe et est du type socket
-w FILE 	Vrai si le fichier existe et est accessible en écriture
-x FILE 	Vrai si le fichier existe et est exécutable
FILE1 -ef FILE2 	Vrai si les fichiers ont le même lien physique
FILE1 -nt FILE2 	Vrai si FILE1 est plus récent que FILE2
FILE1 -ot FILE2 	Vrai si FILE1 est plus ancien que FILE2

```

```
Tests sur les chaines de caractères
Expression 	Code de retour
-n STRING 	Vrai si la longueur de la chaine n'est pas égale à 0
-z STRING 	Vrai si la longueur de la chaine est égale à 0
STRING1 = STRING2 	Vrai si les 2 chaines sont égales
STRING1 != STRING2 	Vrai si les 2 chaines sont différentes
STRING 	Vrai si la chaine n'est pas vide (idem -n)

```


```
Tests sur les nombres
Expression 	Code de retour
INT1 -eq INT2 	Vrai si INT1 est égal à INT2 (=)
INT1 -ge INT2 	Vrai si INT1 est supérieur ou égal à INT2 (>=)
INT1 -gt INT2 	Vrai si INT1 est supérieur à INT2 (>)
INT1 -le INT2 	Vrai si INT1 est inférieur ou égal à INT2 (<=)
INT1 -lt INT2 	Vrai si INT1 est inférieur à INT2 (<)
INT1 -ne INT2 	Vrai si INT1 est différent de INT2 (!=)
```

## Les opérateurs

```

Opérateur 	Signification
! 	Négation
-a 	ET
-o 	OU

```
