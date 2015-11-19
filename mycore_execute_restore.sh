#!/bin/bash

## PREAMBULE
# Ce script est fourni par le CNRS au prestataire mais doit faire l'objet d'une validation par l'exploitant avant installation.

## DESCRIPTION
# Ce Script fait appel au client Tivoli pour la restauration de fichiers/dossiers de la plateforme My CoRe

## CREATION/MISE A JOUR/SUVI
# Créé par jerome.jacques@ext.dsi.cnrs.fr le 01/10/2015


#echo "dsmc rest -PITDate=$1 -subdir=y -rep=y \"$2\""
dsmc rest -PITDate=$1 -subdir=y -rep=y "$2"
exit $?
