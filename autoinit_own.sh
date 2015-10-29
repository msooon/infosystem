#!/bin/bash
# Skript: autoinit_own.sh

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10


source ${0%/*}/config

msearch_opt_args="-pkr40"  #example "-v"
echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[96m Tips: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
if [ -e $ramdisk/category/tips ] ; then # test -e /mnt/... ; then
	POSITION=$[ ( $RANDOM % `msearch $msearch_opt_args -ci -x "done" tips ` )  ]
	msearch $msearch_opt_args -i -o1 -t$POSITION -x "done" tips 
fi

echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[96m Citation: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
if [ -e $ramdisk/category/citation ] ; then # test -e /mnt/... ; then
	POSITION=$[ ( $RANDOM % `msearch $msearch_opt_args -ci -x "done" citation ` )  ]
	msearch $msearch_opt_args -i -o1 -t$POSITION -x "done" citation 
fi

# You can add further searches here
