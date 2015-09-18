#!/bin/bash

#usage
#rm_tag_file [name] [Kategorien ...] 

source ${0%/*}/config

# noch erstes element entfernen - da filename

for element in "$@"
  do
if [ "$element" == "$1" ]
then
filename=`basename "$element"`
else

category_name="'`basename $element`'"

sqlite3 $database "delete from category_item where category_id in (select id from category where name=$category_name union select category.id from category, category_alias where category.id=category_alias.category_id and category_alias.name=$category_name) and item_id in (select id from files where name=\"$filename\") and item_type_id=3"

fi

#echo "Don't forget to add a higher category to the item if you want to find it there!"

done

