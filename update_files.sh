#!/bin/bash

#usage:
# update_files.sh

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

# Die Option -h für Hilfe sollte immer vorhanden sein, die Optionen
# -v und -o sind als Beispiele gedacht. -o hat ein Optionsargument;
# man beachte das auf "o" folgende ":".
while getopts 'vh' OPTION ; do
        case $OPTION in
        v)        VERBOSE=y
                ;;
        h)        usage $EXIT_SUCCESS
                ;;
        \?)        echo "Unbekannte Option \"-$OPTARG\"." >&2
                usage $EXIT_ERROR
                ;;
        *)        echo "Dies kann eigentlich gar nicht passiert sein..."
>&2
                usage $EXIT_BUG
                ;;
        esac
done
# Verbrauchte Argumente überspringen
shift $(( OPTIND - 1 ))

# Eventuelle Tests auf min./max. Anzahl Argumente hier
#if (( $# < 1 )) ; then
#        echo "Mindestens ein Argument beim Aufruf übergeben." >&2
#        usage $EXIT_ERROR
#fi

# Schleife über alle Argumente
#for ARG ; do
#        if [[ $VERBOSE = y ]] ; then
#                echo -n "Argument: "
#        fi
#        echo $ARG
#done


cd $ramdisk/files || exit $EXIT_ERROR
ls -1 >$ramdisk/temp_files


while read line
do
  id=`echo $line | cut -f1 -d'_'`
  filename=`echo $line | cut -f2 -d'_'`  # ,2 -d'|' | sed "s/|/_/g"`
  file_on_disk_with_path=`ls -hal $line | awk -F' ' '//{print $NF}'`
  file_on_disk=`echo $file_on_disk_with_path | awk -F'/' '//{print $NF}'`
  if [[ $filename != $file_on_disk ]] ; then
  mv $file_on_disk_with_path `echo $file_on_disk_with_path | sed "s/$file_on_disk/$filename/g"`
  #mv $filename `"ls -hal $filename | awk -F' ' '//{print $NF}'"`
sqlite3 $database "update files set name=\"$filename\" where id=$id;"
  fi
done < $ramdisk/temp_files

exit $EXIT_SUCCESS
