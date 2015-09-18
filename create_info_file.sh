#!/bin/bash

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
        :)        echo "Option \"-$OPTARG\" benötigt ein Argument." >&2
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
if (( $# < 1 )) ; then
 categories_given=''
fi

#TODO Option für verwendete Kategorien evtl. auch exclude

#bei folgendem select werden infos nur in einer kategorie angezeigt!
sqlite3 $database "select distinct infos.name, infos.id from infos, category, category_item where infos.id=category_item.item_id and category_item.category_id=category.id and infos.zone in (select zone from zones where zones.zones=$zones) order by category.name desc;" | tee $ramdisk/temp_infos


> $ramdisk/infos.txt

# Infos temporär als Dateien anlegen
while read line
do
  id=`echo $line | cut -f2 -d'|'`
  infoname=`echo $line | cut -f1 -d'|'`

echo "" >> $ramdisk/infos.txt
echo "*************************************************" >> $ramdisk/infos.txt
echo "                 $infoname                 " >> $ramdisk/infos.txt

echo "*************************************************" >> $ramdisk/infos.txt

# Bei diesem Select wird info mit einer Kategorie angezeigt
#sqlite3 $database "select category.name, text from infos, category, category_item where infos.id=category_item.item_id and category_item.category_id=category.id and infos.id=$id order by category.name limit 1;" >> $ramdisk/infos.txt


sqlite3 $database "select category.name from infos, category, category_item where infos.id=category_item.item_id and category_item.category_id=category.id and infos.id=$id order by category.name;" | xargs echo >> $ramdisk/infos.txt
echo "" >> $ramdisk/infos.txt
echo "update infos set text='" >> $ramdisk/infos.txt
sqlite3 $database "select text from infos where infos.id=$id;" >> $ramdisk/infos.txt
echo "where id=$id';" >> $ramdisk/infos.txt 

#echo "__________________________________________________" >> $ramdisk/infos.txt

done < $ramdisk/temp_infos


# Am Ende werden noch die Insert-Kommandos eingefügt um Rückimport zu ermöglichen

#sqlite3 $database ".dump infos" >> $ramdisk/infos.txt

exit $EXIT_SUCCESS
