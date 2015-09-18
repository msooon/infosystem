#!/bin/bash

#usage
#rm_link id_[name] 

SCRIPTNAME=$(basename $0 .sh)

source ${0%/*}/config

for element in "$@"
  do

id=`echo $element | cut -f1 -d'_'`

echo id=$id
# wenn sqlite verwendet werden sollte datensatz nicht gelöscht werden (wegen add_item nur letzte id)
sqlite3 $database "update links set name='',source=Null,zone=0,DateAdded=0,pid=0,fid=0,votes=0 where id=$id";

sqlite3 $database "delete from category_item where item_id=$id and item_type_id=2"

sqlite3 $database "delete from item_ref where (item1_id=$id and item1_type_id=2) OR ( item2_id=$id and item2_type_id=2);"

if [[ $USE_HISTORY = y ]] ; then
sqlite3 $database "insert into history (item_id,item_type_id,zones,timestamp,command) values ($id ,2,$zones,(select datetime()),'$SCRIPTNAME');"
fi

done


