# Mycore_backup_restore_user_files
Bash scripts for integration between ownCloud and Tivoli backup system
Current supported repository :
* GitHub
* Subversion
* Apps.owncloud.com
* Local folder

Script backup_mycore.sh backups Owncloud files with 3 options (list of user separated in 3 groups) using Tivoli dsmc command.
Script backup_full_mycore.sh backups all Owncloud user's files using Tivoli dsmc command.
Script mycore_execute_restore.sh launch a restore using Tivoli dsmc command.
Script mycore_restore.sh checks restoration request and run mycore_execute_restore.sh script.
Script mycore_vars.sh set variables.

## Usage

Syntax : 
./backup_mycore.sh [1,2 or 3]
to backup 1st, 2nd or 3rd third of user list.

./mycore_restore.sh
to run restoration requests.

## Contributing

This script is developed for an internal deployement of ownCloud at CNRS (French National Center for Scientific Research).

If you want to be informed about this ownCloud project at CNRS, please contact david.rousse@dsi.cnrs.fr, gilian.gambini@dsi.cnrs.fr or jerome.jacques@ext.dsi.cnrs.fr

## License and Author

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Jerome JACQUES (<jerome.jacques@ext.dsi.cnrs.fr>)
| **Copyright:**       | Copyright (c) 2015 CNRS DSI
| **License:**         | AGPL v3, see the COPYING file.


