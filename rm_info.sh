#!/bin/bash

#usage
#rm_info id 

SCRIPTNAME=$(basename $0 .sh)

source ${0%/*}/config

for element in "$@"
  do

#id=`sqlite3 $database "select id from infos where name=\"$element\""` #Problem auch infos können gleiche namen haben

#id=`basename $element`

id=`basename "$element" | awk -F'_' '//{print $NF}'`

# wenn sqlite verwendet werden sollte datensatz nicht gelöscht werden (wegen add_item nur letzte id)
sqlite3 $database "update infos set name='',text='',zone=0,dateAdded=0,lastModified=0,expiration=0,exp_action=Null where id=$id";

sqlite3 $database "delete from category_item where item_id=$id and item_type_id=1"

sqlite3 $database "delete from item_ref where (item1_id=$id and item1_type_id=1) OR ( item2_id=$id and item2_type_id=1);"

if [[ $USE_HISTORY = y ]] ; then
sqlite3 $database "insert into history (item_id,item_type_id,zones,timestamp,command) values ($id ,1,$zones,(select datetime()),'$SCRIPTNAME');"
fi

done


