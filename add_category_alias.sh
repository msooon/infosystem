#!/bin/bash

#usage:
# add_category_alias [category] [alias]

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
        echo "Usage: $SCRIPTNAME [-v] category_name alias " >&2
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

alias="`basename $2`"
category="`basename $1`"

sqlite3 $database "insert into category_alias (name,category_id) select '$alias', category.id from category where name='$category';"

cd $ramdisk/category || exit $EXIT_FAILURE
cd `find $ramdisk/category -name $category` $$ cd .. 2> /dev/null #only needed in hirachicle mode - possible if before statement
#pwd debug
cd ..
ln -s "$category" "$alias"

exit $EXIT_SUCCESS
