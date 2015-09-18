#!/bin/bash

#usage
#rm_tag_link id_[name] [Kategorien ...] 

source ${0%/*}/config

# noch erstes element entfernen - da infoname

for element in "$@"
  do
if [ "$element" == "$1" ]
then
#infoname=$element
id=`echo $element | cut -f1 -d'_'`
else

category_name="'`basename $element`'"
sqlite3 $database "delete from category_item where category_id in (select id from category where lower(name)=lower($category_name) union select category.id from category, category_alias where category.id=category_alias.category_id and lower(category_alias.name)=lower($category_name)) and item_id=$id and item_type_id=2;" 

fi

done

