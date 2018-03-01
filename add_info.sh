#!/bin/bash

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

#usage
#add_info [name] [Kategorien ...] 

source ${0%/*}/config

mkdir $ramdisk/infos 2> /dev/null
cd $ramdisk/infos || exit

	$EDITOR "$1" 

sed -i "s/'/''/g" "$1"
echo -n "'" > temp_info
cat "$1" >> temp_info
echo -n "'" >> temp_info
#read -p pause #debug

next_id=`sqlite3 $database "select coalesce ( (select id from infos where name='' order by id limit 1),(select max(id)+1 from infos) ); "`
#TODO add args that verbosity work
if [[ $VERBOSE = y ]] ; then
	echo -n "id $next_id will be overwritten"
	sqlite3 $database "select id,name,text from infos where name='' order by id;"
fi

sqlite3 $database "delete from infos where id=$next_id; "

sqlite3 $database "insert into infos (id,name,text,zone,dateAdded,date,lastModified) values ($next_id,'$1',`cat temp_info`,$zones,(select datetime()),(select datetime()),(select datetime()));" && echo "info gespeichert"

echo ""
echo "inserted id: $next_id"

categorys=""

infoname="$1"
categorys="${*:2} `echo $infoname | sed 's/_/ /g'`"

if [[ $VERBOSE = y ]] ; then
	echo -e "\E[35mcategorys: $categorys"; tput sgr0
fi

tag_info "$next_id" $categorys

msearch -kpir1 -w id=$next_id
#msearch -kpi -w id=$next_id

if [[ $USE_HISTORY = y ]] ; then
	sqlite3 $database "insert into history (item_id,item_type_id,categories,zones,timestamp,command) values ($next_id ,1,`echo $categorys | sed "s/ /,/g"`,$zones,(select datetime()),'$SCRIPTNAME');"
fi

customize_info "$next_id"

exit $EXIT_SUCCESS

