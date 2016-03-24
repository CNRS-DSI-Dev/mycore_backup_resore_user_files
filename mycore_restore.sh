#!/bin/bash

## PREAMBULE
# Ce script est fourni par le CNRS au prestataire mais doit faire l'objet d'une validation par l'exploitant avant installation.

## DESCRIPTION

## PREREQUIS
# le client mysql doit être installé
# le script doit avoir accès à la base de données
# le script doit avoir accès en ssh à un des serveurs web


# Chemin des scripts
ScriptDir=""
## VARIABLES
. $ScriptDir/mycore_vars.sh
REST_LOCK_FILE="$TMP/restore.lock"
REST_LOG_FILE="$LOG_DIR/`date +%Y%m%d`_restore.log"

#
# Functions
#
        function removeLock {
                debug=`/bin/rm ${REST_LOCK_FILE} 2>&1`
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
        if [[ -f ${REST_LOCK_FILE} ]]
        then
                exit
        else
                touch ${REST_LOCK_FILE}
        fi


# Stocke la liste des restaurations à traiter dans un fichier de type csv
echo "SELECT CONCAT_WS(\";\",id,uid,path,version,date_request,filetype) FROM oc_user_files_restore WHERE status = '1' ORDER BY date_request;"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names > a_traiter

cat a_traiter > restore_mail_content
printf "\n" >> restore_mail_content

# Lit les lignes du csv et les traite une par une
while IFS=$';\t\n' read tableid uid path version date_request filetype
do
        # Vérifie que la requète a plus de 30 min
        date_30min=`date --date "$tpsreflexion min ago" -u +"%F %T"`
        if [ `date -d "$date_30min" +%s` -ge `date -d "$date_request" +%s` ]
        then
                # Met la date au format PITDate
                date_rest_timestamp=$((`date -d "$date_request" +%s`-(3600*24*$version)))
                date=`date -d @$date_rest_timestamp +%d/%m/%Y`
                # Met en forme le chemin avec les données récupérées
		if [ $filetype == "dir" ] && [ $path != "/" ]
			then
                	cheminresto="$ownclouddatadir$uid/files$path/"
			else
			cheminresto="$ownclouddatadir$uid/files$path"
			fi
                # Passe le status en "en cours de traitement"
                echo "UPDATE oc_user_files_restore SET status = '2' WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
                # Fait appel au script de restauration avec les paramètres précédement renseignées
		printf "$ScriptDir/mycore_execute_restore.sh $date \"$cheminresto\"" >> $REST_LOG_FILE
                $ScriptDir/mycore_execute_restore.sh $date "$cheminresto" >> $REST_LOG_FILE
                # Vérifie le code d'erreur
                if [[ $? = "0" ]]
                then
                # Passe le status en "à scanner"
                echo "UPDATE oc_user_files_restore SET status = '4' WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
                # Affiche la date de fin en base
                echo "UPDATE oc_user_files_restore SET date_end = '`date +\"%F %T\" --utc`' WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
                echo "Restauration de $path de l'utilisateur $uid terminée" >> restore_mail_content
                printf "\n" >> restore_mail_content
                # Renseigne le code d'erreur en base
                echo "UPDATE oc_user_files_restore SET error_code = $? WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
                elif [[ $? = "1" ]]
                then
                # Le fichier n'est pas dispo à la date donnée. Passe le status en "traitée"
                echo "UPDATE oc_user_files_restore SET status = '3' WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
                # Affiche la date de fin en base
                echo "UPDATE oc_user_files_restore SET date_end = '`date +\"%F %T\" --utc`' WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
                echo "$path de l'utilisateur $uid n'est pas disponible à la date donnée" >> restore_mail_content
                printf "\n" >> restore_mail_content
                printf "Bonjour,\n\n$path n'est pas disponible à la date donnée.\n\n--\nService My CoRe\nMy CoRe, partage et nomadisme." | mail -s "$SUBJECT sur $service" $uid $admins
                # Renseigne le code d'erreur en base
                echo "UPDATE oc_user_files_restore SET error_code = $? WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
                else
		echo "SELECT error_code FROM oc_user_files_restore WHERE (id = '$tableid');"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance > error_code
		if [[ $error_code = "NULL" ]]
			then 
	                # Renseigne le code d'erreur en base
	                echo "UPDATE oc_user_files_restore SET error_code = $? WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
	                # Repasse la requète en à traiter
	                echo "UPDATE oc_user_files_restore SET status = '1' WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
			else
			printf "Bonjour,\n\nLa restauration de $path a échouée.\n\n--\nService My CoRe\nMy CoRe, partage et nomadisme." | mail -s "$SUBJECT sur $service" $uid $admins
			fi
                echo "Restauration de $path de l'utilisateur $uid échouée" >> restore_mail_content
                printf "\n" >> restore_mail_content
                fi
        fi
done < a_traiter

# pied de mail
echo -e "\n"$0" executé le "`date '+%d %B %Y'`" sur $HOSTNAME" >> restore_mail_content
printf "\n--\nService My CoRe\nMy CoRe, partage et nomadisme." >> restore_mail_content
# envoi du mail
removeLock
if [[ $a_traiter != "" ]]
	then cat restore_mail_content | mail -s "$SUBJECT sur $service" -r "$expname<$expadd>" $admins
fi

