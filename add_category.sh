#!/bin/bash

#usage:
# add_category [parent]/[name] 

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10


source ${0%/*}/config

# Variablen für Optionsschalter hier mit Default-Werten vorbelegen
#VERBOSE=n
OPTFILE=""

# Funktionen
function usage {
echo "Usage: $SCRIPTNAME [-v] category " >&2
[[ $# -eq 1 ]] && exit $1 || exit $EXIT_FAILURE
}

category=`basename $1`

# if category allready exists but in wrong hirarchy 
#category_with_old_path=`find $ramdisk -name $category`
#rmdir $category_with_old_path 2> /dev/null 
#rm $category_with_old_path 2> /dev/null

if [[ $category_flat_mode != 1 ]] ; then
	mkdir $ramdisk/category/$1 2> /dev/null
	cd $ramdisk/category/$1 2> /dev/null
	cd ..
	parent=`pwd | awk -F'/' '//{print $NF}'`

fi

if [[ $category_flat_mode > 0 ]] ; then
	touch $ramdisk/category/$category 2> /dev/null
	directory=`pwd`
	parent=`dirname "$directory/$1" | awk -F'/' '//{print $NF}'`
fi

echo "category: $category"
echo "parent: $parent"

if [[ $parent = category ]] ; then
	dbquery="insert into category (name,parent,zone) select distinct \"$category\", 0, $zones from category where lower(\"$category\") not in (select lower(name) from category) and lower(\"$category\") not in (select lower(name) from category_alias);"
	if [[ $VERBOSE = y ]] ; then
		echo dbquery: $dbquery
		echo ""
	fi
	sqlite3 "$database" "$dbquery" 
	exit $EXIT_SUCCESS
fi

dbquery="insert into category (name,parent,zone) select distinct \"$category\", category.id, $zones from category where (name=\"$parent\" or id in (select category.id from category, category_alias where category.id = category_alias.category_id and category_alias.name=\"$parent\")) AND lower(\"$category\") not in (select lower(name) from category) not in (select lower(name) from category_alias);"

if [[ $VERBOSE = y ]] ; then
	echo dbquery: $dbquery
	echo ""
fi
sqlite3 "$database" "$dbquery"

# 2015-10-11 msoon: if category exists but in wrong hirarchy or zone - change it
#falls Kategorie schon existierte aber Einordnung geändert werden soll

#TODO Error handling
parent_id=`sqlite3 $database "select id from category where name=\"$parent\" or id in (select category.id from category, category_alias where category.id = category_alias.category_id and category_alias.name=\"$parent\");"`

dbquery="update category set parent=\"$parent_id\",zone=$zones where name=\"$category\" or id in (select category.id from category, category_alias where category.id = category_alias.category_id and category_alias.name=\"$category\");"

if [[ $VERBOSE = y ]] ; then
	echo dbquery: $dbquery
	echo ""
fi
sqlite3 "$database" "$dbquery"

#TODO Probleme beheben - funktioniert nur aus Verzeichniss /category und tree kann bei weiteren Unterverzeichnissen nicht bereinigt werden

exit $EXIT_SUCCESS
