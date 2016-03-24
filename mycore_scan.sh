#!/bin/bash

## PREAMBULE
# Ce script est fourni par le CNRS au prestataire mais doit faire l'objet d'une validation par l'exploitant avant installation.

## DESCRIPTION

## PREREQUIS
# Le Script doit être déposer sur un des serveurs hébergeant OwnCloud
# Le Script doit avoir accès à la base de donnée et l'app user_files_restore doit être actif
# Le Script doit être exécutable

## CREATION/MISE A JOUR/SUVI
# Créé par jerome.jacques@ext.dsi.cnrs.fr le 22/03/2016

mycore_root=""
user_apache=""
command=$0
LOCK_FILE=""
LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/`date +%Y%m%d`_scan.log"
db_host=""
db_user=""
db_port=""
db_passwd=""
instance=""
# Adresse expediteur pour l'envoi aux admins
expadd=""
# Nom expediteur
expname="Service My CoRe"
SUBJECT="My CoRe - Restauration de fichiers"
service=""
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
# Stocke la liste des répertoires à scanner dans un fichier de type csv
echo "SELECT CONCAT_WS(\";\",id,uid,path) FROM oc_user_files_restore WHERE status = '4' ORDER BY id;"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names > a_scanner

# Lit les lignes du csv et les traite une par une
while IFS=$';\t\n' read tableid uid chemin
do
	# Scan le dossier de l'utilisateur
	su $user_apache -s $mycore_root/occ files:scan $uid
	printf "Scan du dossier de $uid. \n" >> $LOG_FILE
        # Envoi de mail à l'utilisateur
        printf "Bonjour,\n\nLa restauration de $chemin est terminée\n\n--\nService My CoRe\nMy CoRe, partage et nomadisme." | mail -s "$SUBJECT sur $service" -r "$expname<$expadd>" $uid
	# Changement du status en traitée
	echo "UPDATE oc_user_files_restore SET status = '3' WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
done < a_scanner
removeLock


