#!/bin/bash

#usage
#add_link [name] [url] [Kategorien ...] #später noch andere als [defaultzone] ermöglichen

source ${0%/*}/config

choice=""

next_id=`sqlite3 $database "select coalesce ( (select id from links where name='' order by id limit 1),(select max(id)+1 from links) ); "`

sqlite3 $database "delete from links where id=$next_id; "

sqlite3 $database "insert into links (id,name,source,dateAdded,zone) values ('$next_id','$1','$2',(select datetime()),$zones);"

echo "inserted id: $next_id"


categorys=""

linkname="$1"
url="$2"
categorys="${*:3}"

if [[ $VERBOSE = y ]] ; then
echo -e "\E[35mcategorys: $categorys"; tput sgr0
fi

tag_link "$next_id" $categorys

#customize_link "$next_id" #Nutzen an dieser Stellen zweifelhaft da es als sub-script aufgerufen werden muss

echo ""

