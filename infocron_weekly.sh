#!/bin/bash

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

source ${0%/*}/config

#vor history aufräumen sichern
#echo "history wird gesichert und bereinigt ..."
#echo ""

#date_to_del=`date -d "5 month ago" +%Y-%m-%d`
#sqlite3 -separator '","' $database "select * from history where Date(timestamp)<Date(\"$date_to_del\");" >> $cached_files/deleted_history_enries
#sqlite3 $database "delete from history where Date(timestamp)<Date(\"$date_to_del\"); 

# search for updated websites
sqlite3 $database "select distinct links.id, links.name, links.source from links,category_link,category where links.id=category_link.item_id and category_link.category_id=2;" > $ramdisk/sites_to_check
#> $ramdisk/sites_to_check #temporär abgeschaltet

while read line
do
	id=`echo $line | cut -f1 -d'|'`
	name=`echo $line | cut -f2 -d'|'`
	url=`echo $line | cut -f3 -d'|'`
	mkdir $cached_files/$id   2> /dev/null
	cd $cached_files/$id
	mv new old 2> /dev/null
	wget -O temp --user-agent="'"$useragent"'" $url 2> /dev/null
	grep -v '<lastBuildDate>\|<pubDate>' temp > new  #needed for rss
	rm temp
	if [ -e prepare.sh ] ; then
		./prepare.sh
	fi
	if [ -f "old" ]
	then
		#	diff -q new old
		diff new old > "$ramdisk/diff"
		if (( $? != 0 )) ; then #Result of diff
			tag_link "$id" todo
		fi 
		grep -e '^< ' $ramdisk/diff >  $ramdisk/$id"_update"
	fi
done < $ramdisk/sites_to_check

# delete old done tags
if [[ $VERBOSE = y ]] ; then
	echo "delete old done tags"
	echo "delete from category_item where item_type_id=1 and category_id=10 and item_id in (select id from infos where date()>date(date,'+4 month') );"
fi

sqlite3 $database "delete from category_item where item_type_id=1 and category_id=10 and item_id in (select id from infos where date()>date(date,'+4 month') );"

# biweekly and monthly

sqlite3 $database "update infos set date=DateTime(date,'+14 days') where id in (select item_id from category_item where item_type_id=1 and category_id=6) and DateTime()>DateTime(date);"

sqlite3 $database "update infos set date=DateTime(date,'+1 month') where id in (select item_id from category_item where item_type_id=1 and category_id=4) and DateTime()>DateTime(date);"

# yearly (monthly cronjob would be enough)
sqlite3 $database "update infos set date=DateTime(date,'+1 year') where id in (select item_id from category_item where item_type_id=1 and category_id=9) and DateTime()>DateTime(date);"

	 # delete old cached files
find $cached_files/*/ -maxdepth 2 -mtime +28 -name old -exec rm -rv -- "{}" \;
find $cached_files/*/ -maxdepth 2 -mtime +28 -name new -exec rm -rv -- "{}" \; 2> /dev/null >>/dev/null
# delete empty directories
find $cached_files/*/ -maxdepth 2 -type d -exec rmdir -v -- "{}" \; 2> /dev/null >>/dev/null

#find $cached_files/*/ -maxdepth 2 -mtime +28  | grep '[[:digit:]]\{1,6\}/old' 

