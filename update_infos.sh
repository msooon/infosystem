#!/bin/bash

#usage:
# update_infos.sh

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

source ${0%/*}/config

# Variablen für Optionsschalter hier mit Default-Werten vorbelegen
VERBOSE=n
OPTFILE=""

# Funktionen
function usage {
        echo "Usage: $SCRIPTNAME [-h] [-v]" >&2
        [[ $# -eq 1 ]] && exit $1 || exit $EXIT_FAILURE
}


cd $ramdisk/infos || exit $EXIT_ERROR
ls -1 > $ramdisk/temp_infos

while read line
do
	id=`echo "$1" | awk -F'_' '//{print $NF}'`
	#id=`echo $line | cut -f2 -d'_'`
  #infoname=`sqlite3 $database "select name || '_' || id from infos where id=$id"`
	#`echo $line | cut -f1 | sed "s/_$id//g"`  # ,2 -d'|' | sed "s/|/_/g"`
#  set_date=`echo "$infoname" | cut -f1 -d'_'`

#echo "text=\"`cat $infoname`\"" #debug
echo infoname: $line
sqlite3 $database "update infos set text=\"`cat $line`\" where id=$id;"
#sqlite3 $database "update infos set name=\"$infoname\",dateAdded='$set_date' where id=$id;"

done < $ramdisk/temp_infos

exit $EXIT_SUCCESS
