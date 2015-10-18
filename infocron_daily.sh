#!/bin/bash

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

source ${0%/*}/config

# weekly
sqlite3 $database "update infos set date=DateTime(date,'+7 day') where id in (select item_id from category_item where item_type_id=1 and category_id=3) and DateTime()>DateTime(date) and (DateTime()<=DateTime(expiration) or expiration is null);"

# expired infos
expired_todel=`sqlite3 $database "select id from infos where DateTime()>DateTime(expiration) and exp_action=0;"`
rm_info $expired_todel

#other expired
sqlite3 -separator ' ' $database "select distinct infos.id, category.name from infos, category where category.id=infos.exp_action and DateTime()>DateTime(expiration) and date()<date(date,'+2 month');"	> $ramdisk/expired

while read line
do
	#		item_id=`echo $line | cut -d'|' -f1`
	#		category_id=`echo $line | cut -d'|' -f2`
	#mögliches Problem könnte sein das todo nicht gesetzt wird wenn item in done
	tag_info $line
	#	  tag_info $item_id `select name from category where id=$category_id`
done < $ramdisk/expired

#expired_done=`sqlite3 $database "select id from infos where date()>date(expiration) and exp_action=10;"`
#tag_info $expired_done "done"

