#!/bin/bash

## PREAMBULE
# Ce script est fourni par le CNRS au prestataire mais doit faire l'objet d'une validation par l'exploitant avant installation.

## DESCRIPTION

## PREREQUIS
# le client mysql doit être installé
# le script doit avoir accès à la base de donnée


## VARIABLES
. ./mycore_vars.sh

# Stocke la liste des restaurations à traiter dans un fichier de type csv
echo "SELECT CONCAT_WS(\";\",id,uid,path,version,date_request) FROM oc_user_files_restore WHERE status = '1' ORDER BY date_request;"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names > a_traiter
#echo "SELECT id,uid,path,version,date_request FROM oc_user_files_restore WHERE status = '1' ORDER BY date_request"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance --skip-column-names > a_traiter

cat a_traiter > mail_content
printf "\n" >> mail_content

# Lit les lignes du csv et les traite une par une
while IFS=$';\t\n' read tableid uid path version date_request
do
	# Vérifie que la requête a plus de 30 min
	date_30min=`date --date "30 min ago" -u +"%F %T"`
	if [ `date -d "$date_30min" +%s` -ge `date -d "$date_request" +%s` ]
	then
		# Met la date au format PITDate
		date=`date --date "$version days ago" +%m/%d/%Y`
		# Met en forme le chemin avec les données récupérées
		cheminresto="$ownclouddatadir$uid/files$path"
		# Passe le status en "en cours de traitement"
		echo "UPDATE oc_user_files_restore SET status = '2' WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
		# Fait appel au script de restauration avec les paramètres précédement renseignés
		./mycore_execute_restore.sh $date \"$cheminresto\"
		# Vérifie le code d'erreur
		if [[ $? = "0" ]]
		then
		# Passe le status en "traité et renseigne la date de fin en bdd"
		echo "UPDATE oc_user_files_restore SET status = '3' , date_end = '`date +\"%F %T\" --utc`' WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
		echo "Restauration de $path de l'utilisateur $uid terminée" >> mail_content
		printf "\n" >> mail_content
		printf "Bonjour,\n\nLa restauration de $path est terminée\n\n--\nService My CoRe\nMy CoRe, partage et nomadisme." > mail_user
		else
		# Renseigne le code d'erreur en base
		echo "UPDATE oc_user_files_restore SET error_code = $? WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
		# Repasse la requête en à traiter
		echo "UPDATE oc_user_files_restore SET status = '1' WHERE id = '$tableid';"| mysql -h $db_host -u $db_user -P $db_port -p$db_passwd $instance
		echo "Restauration de $path de l'utilisateur $uid échouée" >> mail_content
		printf "\n" >> mail_content
		printf "Bonjour,\n\nLa restauration de $path a échouée\n\n--\nService My CoRe\nMy CoRe, partage et nomadisme." > mail_user
		fi
	        cat mail_user | mail -s "$SUBJECT sur $service" -r "$expname<$expadd>" $uid
	fi
done < a_traiter

# pied de mail
echo -e "\n"$0" executé le "`date '+%d %B %Y'`" sur $HOSTNAME" >> mail_content
printf "\n--\nService My CoRe\nMy CoRe, partage et nomadisme." >> mail_content
# envoi du mail
cat mail_content | mail -s "$SUBJECT sur $service" -r "$expname<$expadd>" $admins

