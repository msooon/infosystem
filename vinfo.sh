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
        echo "Usage: $SCRIPTNAME [-h] [-v] info_name" >&2
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

	#not elegant but works in most cases
	id=`echo $1 | awk -F'/' '//{print $NF}' | awk -F'_' '//{print $NF}'`
	infofile=`echo $ramdisk/infos/*_$id`
	infoname=`echo $infofile | awk -F'/' '//{print $NF}'`

#echo id=$id
#echo infofile=$infofile
#echo infoname=$infoname
	if [ -e "$infofile" ] ; then
	cp "$infofile" "$cached_files/prev_versions/$infoname`date +%Y%m%d%H%M%S`"

	$EDITOR "$infofile"  # info-datei öffnen 
else
#echo "temporarly info-file not found - please search again: msearch -s [info]"
	 #should check that info exists
	 read -n 1 -p "Info not in Cache - try to find in DB again (Y/n)" choice #

	 if [[ $choice = n ]] ; then
		    echo ""
				exit $EXIT_SUCCESS
				 else
  msearch -kpiw id="$id"
	vinfo "$id"
	exit $EXIT_SUCCESS #at least this command
fi
	#exit $EXIT_FAILURE # Wenn info-datei nicht existiert werden kann beenden um leere Datei zu vermeiden
fi

  #id=`echo "$1" | awk -F'_' '//{print $NF}'`
  sed -i "s/'/''/g" "$infofile"
  #infoname=`echo $1 | cut -f1`  # ,2 -d'|' | sed "s/|/_/g"`
sqlite3 $database "update infos set text='`cat \"$infofile\"`', lastModified=(select datetime()) where id=$id;"
  sed -i "s/''/'/g" "$infofile" #needed if you want to reopen the file without search again

#geöffnete Dateien höher bewerten, damit sie oben erscheinen
sqlite3 $database "update infos set rating=rating+10 where id=$id;"
sqlite3 $database "update infos set votes=votes+10 where id=$id;"


exit $EXIT_SUCCESS
