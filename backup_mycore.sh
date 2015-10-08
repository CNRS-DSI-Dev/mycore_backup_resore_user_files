#!/bin/bash

## PREAMBULE
# Ce script est un exemple de faisabilité pour une demande du CNRS dans le cadre du projet My CoRe. Il doit être adapté et configuré pour une utilisation en production par le prestataire, et ne doit pas être considéré comme utilisable tel quel sans expertise préalable dessus

## DESCRIPTION
# Script dedié à scanner le file system de données d'ownCloud via clamAV. Il envoie un email à une adresse d'administration ainsi qu'à l'utilisateur (si l'uid de ce dernier à la forme d'un email)
# Le dossier de quarantaine doit être configuré pour une purge, typiquement à +30jours

## PREREQUIS
# Installer Tivoli dsmc

## CREATION/MISE A JOUR/SUVI
# Créé par jerome.jacques@ext.dsi.cnrs.fr le 01/10/2015

# chargement des variables
. ./mycore_vars.sh
# Sujet du mail
mailsubject='My CoRe - Sauvegarde'
# numéro de liste {1|2|3}
liste=$1
# commande exécutée
command=$0
LOCK_FILE="backup_$1.lock"


#
# Functions
#
        function removeLock {
                debug=`/bin/rm ${LOCK_FILE} 2>&1`
                if [[ $? -ge "1" ]]
                then
                        # TODO Cmd fail + log
                        writeLog "FAIL removeLock : $debug"
                        exit 2
                fi

        }

#
# Check du verrou
#
        if [[ -f ${LOCK_FILE} ]]
        then
                exit
        else
                touch ${LOCK_FILE}
        fi


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
		printf "Sauvegarde de $i.\n" >> $temporarymailfile
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
                printf "Sauvegarde de $i.\n" >> $temporarymailfile
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
                printf "Sauvegarde de $i.\n" >> $temporarymailfile
#               /usr/bin/dsmc inc "$i/files/" -subdir=yes
                done
fi

if [[ $liste != "1" ]] && [[ $liste != "2" ]] && [[ $liste != "3" ]]
then
echo "usage - $command [1, 2 ou 3]"
fi

removeLock
echo "\nFin de la sauvegarde $liste" >> $temporarymailfile
mail -s "$mailsubject" -b $admins -r "$mailfrom" -Sreplyto=$expadd $mailto < $temporarymailfile
