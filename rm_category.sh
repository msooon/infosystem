#!/bin/bash

#usage
#rm_category [name] 

source ${0%/*}/config

#cd $ramdisk/category || exit

for element in "$@"
do

	name="'`basename $element`'"

	category_id=`sqlite3 $database "select id from category where name=$name;"`
	parent_id=`sqlite3 $database "select parent from category where id=$category_id;"`

if [[ $VERBOSE = y ]] ; then
	echo category_name: $name
	echo category_id: $category_id
	echo parent_id: $parent_id
	echo ""
fi

echo parent to add sub-categorys and items: `sqlite3 $database "select name from category where id=$parent_id;"`
echo ""

#	children_ids=`sqlite3 $database "select id from category where parent=$category_id);"`
	sqlite3 $database "update category set parent=$parent_id where id in (select id from category where parent=$category_id);"
	sqlite3 $database "update category_item set category_id=$parent_id where category_id=$category_id and $parent_id!=0;"

	# if the category has no parent - delete tags from the items
	sqlite3 $database "delete from category_item where category_id=$category_id;"

	alias_todel=`sqlite3 $database "select name from category_alias where category_id in (select id from category where name=$name);"`
	echo -n "deleted aliases: $alias_todel"

	rm_category_alias $alias_todel
	echo ""

	sqlite3 $database "delete from category where id=$category_id;"

	rm -r $element 2> /dev/null

done


