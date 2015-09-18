#!/bin/bash

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

#usage
#tag_info id_[name] [Kategorien ...] 

source ${0%/*}/config

# noch erstes element entfernen - da infoname

for element in "$@"
  do
if [ "$element" == "$1" ]
then
#infoname=$element
id=`echo "$1" | awk -F'_' '//{print $NF}'`
else

category_name="'`basename $element`'"

# 2013-04-02 msoon: only using item_id and prevent adding parent categorys

dbquery="select id from category where (lower(name)=lower($category_name) OR id in (select category.id from category, category_alias where category.id=category_alias.category_id and lower(category_alias.name)=lower($category_name))) and 
id not in 
( 
  select distinct parent from category where 
  id in (select category_id from category_info where item_id=$id)
  OR
  id in (select distinct parent from category where id in (select category_id from category_info where item_id=$id) )
  OR
  id in  (select parent from category where id in (select distinct parent from category where id in (select category_id from category_info where item_id=$id) ))
  OR
  id in (select parent from category where id in ( select parent from category where id in (select distinct parent from category where id in (select category_id from category_info where item_id=$id) )))
  OR
  id in (select parent from category where id in (select parent from category where id in ( select parent from category where id in (select distinct parent from category where id in (select category_id from category_info where item_id=$id) )))
  )  
)"


if [[ $VERBOSE = y ]] ; then
echo dbquery: "$dbquery;"
echo ""
echo -e "\E[35mcategory to add: `sqlite3 \"$database\" \"select name from category where id in ($dbquery);\"`"; tput sgr0
fi

sqlite3 "$database" "insert into category_item (category_id,item_id,item_type_id) values (($dbquery),$id,1);" 2> /dev/null


# to delete parents if subcategory is added
dbquery="select name from category where 
id in 
(
  select distinct parent from category where 
  id in (select id from category where lower(name)=lower($category_name))
  OR
  id in (select parent from category where id in (select id from category where lower(name)=lower($category_name)) )
  OR
  id in (select parent from category where id in (select parent from category where id in (select id from category where lower(name)=lower($category_name)) ))
  OR
  id in (select parent from category where id in ( select parent from category where id in (select parent from category where id in (select id from category where lower(name)=lower($category_name)) )))
  OR
  id in (select parent from category where id in (select parent from category where id in ( select parent from category where id in (select parent from category where id in (select id from category where lower(name)=lower($category_name)) )))));" 

if [[ $VERBOSE = y ]] ; then
echo dbquery: $dbquery
echo ""
fi

sqlite3 "$database" "$dbquery"  | xargs echo > $ramdisk/rm_tag_categorys

if [[ $VERBOSE = y ]] ; then
echo -e "\E[35mcategorys to remove: `cat \"$ramdisk/rm_tag_categorys\"`"; tput sgr0
echo ""
fi

rm_tag_info "$id" `cat $ramdisk/rm_tag_categorys`

if [[ $USE_HISTORY = y ]] ; then
sqlite3 $database "insert into history (item_id,item_type_id,categories,zones,timestamp,command) values ($id) ,1,`echo $category_name | sed "s/','/,/g"`,$zones,(select datetime()),'$SCRIPTNAME');"
fi

fi

done

