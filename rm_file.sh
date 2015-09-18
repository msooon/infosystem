#!/bin/bash

#usage
#rm_file [id_filename] 

SCRIPTNAME=$(basename $0 .sh)

source ${0%/*}/config

for element in "$@"
  do


#id=`sqlite3 $database "select id from files where name=\"$element\""` # Ansatz ist nicht gut da mehrereDateien den gleichen namen haben können - abhilfe würde inode ermitteln bringen

id=`basename $element | cut -f1 -d'_'`

#echo "update files set name='',mediatype='',disksource='',inode='',backup=null,source='',rating=0,zone=0,votes=0,bdisksource='',binode=0 where id=$id"

# wenn sqlite verwendet werden sollte datensatz nicht gelöscht werden (wegen add_item nur letzte id)
sqlite3 $database "update files set name='',mediatype='',disksource=null,inode=null,backup=null,source='',rating=0,zone=0,votes=0,bdisksource='',binode=0 where id=$id"

#echo "delete from category_item where item_id=$id and item_type_id=3"
sqlite3 $database "delete from category_item where item_id=$id and item_type_id=3"

sqlite3 $database "insert into history (item_id,item_type_id,zones,timestamp,command) values ($id ,3,$zones,(select datetime()),'$SCRIPTNAME');"

done


