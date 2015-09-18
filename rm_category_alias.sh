#!/bin/bash

#usage
#rm_category [name] 

source ${0%/*}/config

#cd $ramdisk/category || exit

for element in "$@"
  do

name="'`basename $element`'"

sqlite3 $database "delete from category_alias where name=$name;"

echo "element: $element"
rm $element 2> /dev/null

done


