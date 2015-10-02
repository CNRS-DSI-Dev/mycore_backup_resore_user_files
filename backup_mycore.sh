#!/bin/bash

## PREAMBULE
# Ce script est un exemple de faisabilité pour une demande du CNRS dans le cadre du projet My CoRe. Il doit être adapté et configuré pour une utilisation en production par le prestataire, et ne doit pas être considéré comme utilisable tel quel sans expertise préalable dessus

## DESCRIPTION
# Script dedié à scanner le file system de données d'ownCloud via clamAV. Il envoie un email à une adresse d'administration ainsi qu'à l'utilisateur (si l'uid de ce dernier à la forme d'un email)
# Le dossier de quarantaine doit être configuré pour une purge, typiquement à +30jours

## VARIABLES
# directory=repertoire des données MyCore (partagé entre les différents serveurs Apache/ownCloud et la(les) clamAV
# quarantainedirectory=répertoire de quarantaine
# listeusersdirectory=fichiers qui contient la liste des utilisateurs présents dans sdirectory
# temporarymailfile=fichier de travail pour la construction du email
# scanedfiles=fichier de travail pour le scan des fichiers par l'antivirus
# patterntoignoreinownclouddatadir=éléments à ignorer dans $directory
# admins=@email à qui envoyer dans tous les cas les mails d'avertissement si un fichier est trouvé
# mailfrom=@mail FROM
# expadd=@mail REPLY-TO
# mailsubject=sujet du mail
# scriptdir=répertoire du script
# removescanresultafterrun=flag pour supprimer ou pas le fichier @scanedfiles

## PREREQUIS
# Ce script nécessite que clamAV soit installé sur l'OS. Voici pour mémo. les commandes passées par le CNRS en test
# 	yum install clamd
# Planifier les mises à jour automatique:
# 	freshclam -d
# 	activer le démon clamd:
# 	chkconfig clamd on
# 	/etc/init.d/clamd start

## CREATION/MISE A JOUR/SUVI
# Créé par jerome.jacques@ext.dsi.cnrs.fr le 01/12/2014
# Mise à jour par david.rousse@dsi.cnrs.fr le 02/12/2014
# Voir https://mantis.cnrs.fr/view.php?id=35163 en interne CNRS 

# Mise à jour du 04/07/2015
# Le scan global a été remplacé par des scans individuels des répertoires users pour permettre d'avoir un dossier de
# quarantaine propre à chaque utilisateur.
# Les fichiers sont mis dans un dossier de quarantaine, puis zippés et mis en lecture seule.

# chargement des variables
. ./mycore_vars.sh
# Sujet du mail
mailsubject='My CoRe - Sauvegarde'
# numéro de liste {1|2|3}
liste=$1
# commande exécutée
command=$0

# CONTENU


# Sauvegarde la liste entrée en argument (1, 2 ou 3)
#Initialisation du corps du message
> $temporarymailfile
if [[ $liste == "1" ]]
then
	#récupération des dossiers des utilisateurs à sauvegarder
	find $ownclouddatadir/ -maxdepth 1 -name '[abcdefghABCDEFGH]*' | egrep -v "$patterntoignoreinownclouddatadir" > $listeusersdirectory/users1.txt
	#On sauvegarde user par user 
	for i in $( < $listeusersdirectory/users1.txt)
		do
		echo "/usr/bin/dsmc inc \"$i/files/\" -subdir=yes"
		printf "Sauvegarde de $i\n" >> $temporarymailfile
#		/usr/bin/dsmc inc "$i/files/" -subdir=yes
		done
fi
if [[ $liste == "2" ]]
then
        #récupération des dossiers des utilisateurs à sauvegarder
        find $ownclouddatadir/ -maxdepth 1 -name '[ijklmnopIJKLMNOP]*' | egrep -v "$patterntoignoreinownclouddatadir" > $listeusersdirectory/users2.txt
        #On sauvegarde user par user
        for i in $( < $listeusersdirectory/users2.txt)
                do
                echo "/usr/bin/dsmc inc \"$i/files/\" -subdir=yes"
                printf "Sauvegarde de $i\n" >> $temporarymailfile
#               /usr/bin/dsmc inc "$i/files/" -subdir=yes
                done
fi
if [[ $liste == "3" ]]
then
        #récupération des dossiers des utilisateurs à sauvegarder
        find $ownclouddatadir/ -maxdepth 1 -name '[qrstuvwxyzQRSTUVWXYZ0123456789]*' | egrep -v "$patterntoignoreinownclouddatadir" > $listeusersdirectory/users3.txt
        #On sauvegarde user par user
        for i in $( < $listeusersdirectory/users3.txt)
                do
                echo "/usr/bin/dsmc inc \"$i/files/\" -subdir=yes"
                printf "Sauvegarde de $i\n" >> $temporarymailfile
#               /usr/bin/dsmc inc "$i/files/" -subdir=yes
                done
fi

if [[ $liste != "1" ]] && [[ $liste != "2" ]] && [[ $liste != "3" ]]
then
echo "usage - $command [1, 2 ou 3]"
fi

echo "fin de la sauvegarde $liste" >> $temporarymailfile
mail -s "$mailsubject" -b $admins -r "$mailfrom" -Sreplyto=$expadd $mailto < $temporarymailfile
