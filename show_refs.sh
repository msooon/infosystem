#!/bin/bash
# Skript:       skript.sh
# Zweck:        Basis für eigene Skripte, enthaelt bereits
#               einige Skript-Standardelemente (usage-Funktion,
#               Optionen parsen mittels getopts, vordefinierte
#               Variablen...)

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
        echo "Usage: $SCRIPTNAME [-h] [-v] [-o arg] file ..." >&2
        [[ $# -eq 1 ]] && exit $1 || exit $EXIT_FAILURE
}

# Die Option -h für Hilfe sollte immer vorhanden sein, die Optionen
# -v und -o sind als Beispiele gedacht. -o hat ein Optionsargument;
# man beachte das auf "o" folgende ":".
while getopts ':o:vh' OPTION ; do
        case $OPTION in
        v)        VERBOSE=y
                ;;
        o)        OPTFILE="$OPTARG"
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
        echo "Mindestens ein Argument beim Aufruf übergeben." >&2
        usage $EXIT_ERROR
fi

#TODO $2 für item_id
#sqlite3 $database "select distinct name from infos, item_ref where infos.id!=$1 and (infos.id=item1_id or infos.id=item2_id) and ((item1_type_id=1 and item1_id=$1) or (item2_type_id=1 and item2_id=$1))"
sqlite3 $database "select distinct (name||'_'||infos.id) from infos, item_ref where (infos.id=item1_id and item1_type_id=1) and (item2_id=$1 and item2_type_id=1) union select distinct (name||'_'||infos.id) from infos, item_ref where (infos.id=item2_id and item2_type_id=1) and (item1_id=$1 and item1_type_id=1)"
sqlite3 $database "select distinct name, source from links, item_ref where (links.id=item1_id and item1_type_id=1) and (item2_id=$1 and item2_type_id=1) union select distinct name, source from links, item_ref where (links.id=item2_id and item2_type_id=2) and (item1_id=$1 and item1_type_id=1)"
sqlite3 $database "select distinct (files.id||'_'||name) from files, item_ref where (files.id=item1_id and item1_type_id=1) and (item2_id=$1 and item2_type_id=1) union select distinct (files.id||'_'||name) from files, item_ref where (files.id=item2_id and item2_type_id=3) and (item1_id=$1 and item1_type_id=1)"

#sqlite3 $database "select distinct name from links, item_ref where links.id!=$1 and (links.id=item1_id or links.id=item2_id) and ((item1_type_id=2 and item1_id=$1) or (item2_type_id=2 and item2_id=$1))"
#sqlite3 $database "select distinct name from files, item_ref where files.id!=$1 and (files.id=item1_id or files.id=item2_id) and ((item1_type_id=3 and item1_id=$1) or (item2_type_id=3 and item2_id=$1))"

# Schleife über alle Argumente
for ARG ; do
        if [[ $VERBOSE = y ]] ; then
                echo -n "Argument: "
        fi
       # echo $ARG
done

exit $EXIT_SUCCESS
