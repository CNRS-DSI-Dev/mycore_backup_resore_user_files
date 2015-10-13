#!/bin/bash

## PREAMBULE
# Ce script est un exemple de faisabilité pour une demande du CNRS dans le cadre du projet My CoRe. Il doit être adapté et configuré pour une utilisation en production par le prestataire, et ne doit pas être considéré comme utilisable tel quel sans expertise préalable dessus

## DESCRIPTION
# Le script permet de sauvegarder les dossiers utlisateurs via un client Tivoli.

## PREREQUIS
# Installer Tivoli dsmc

## CREATION/MISE A JOUR/SUVI
# Créé par jerome.jacques@ext.dsi.cnrs.fr le 01/10/2015

# chargement des variables
. /XXX/mycore_vars.sh
# Sujet du mail
mailsubject="My CoRe - Sauvegarde $1"

# commande exécutée
command=$0
LOCK_FILE="/XXX/tmp/backup_full.lock"
LOG_FILE="/XXX/tmp/`date +%Y%m%d`_backup_full.log"


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


# Sauvegarde
#Initialisation du corps du message
> $temporarymailfile
echo "Lancement de la sauvegarde le `date '+%d %B %Y à %T'`." >> $temporarymailfile
/usr/bin/dsmc inc -subdir=yes $ownclouddatadir >> $LOG_FILE
echo "Sauvegarde terminée le `date '+%d %B %Y à %T'`." >> $temporarymailfile
removeLock
mail -s "$mailsubject" -b $admins -r "$mailfrom" -Sreplyto=$expadd $mailto < $temporarymailfile

