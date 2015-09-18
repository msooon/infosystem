#!/bin/bash

#usage
#add_lightning_entries  #später noch andere als [defaultzone] ermöglichen

source ${0%/*}/config


read -n 1 -p "view/edit config before? (Y/n) " choice
if [[ $choice == "n" ]] ; then
	echo ""
	echo "existing config will be used"
else
	$EDITOR ${0%/*}/config
	source ${0%/*}/config
fi
echo ""

read -n 1 -p "What should happen if entries expire? (d=tag-with-done t=auto-terminate [other_key]=nothing) " choice

if [[ $choice == "d" ]] ; then
	echo ""
	echo ""
	echo "info will be tagged with done after expiration date"
	exp_action=10
elif [[ $choice == "t" ]] ; then
	echo ""
	echo ""
	echo "info will be deleted after expiration date!"
	exp_action=0
else
	exp_action=Null
fi

cd /category

#TODO Better way is to rebuild the cache from Infosystem-DB
touch $cached_files/lightning_entries # needed if file not exists
cat $cached_files/lightning_entries > $ramdisk/lightning_entries_last
sort -u $ramdisk/lightning_entries_last > $cached_files/lightning_entries_last

sqlite3 -separator ',' $lighning_db "select replace(replace(replace(title,'\"',' '),',',' '),'|',' '),substr(event_start,1,10),id,substr(event_end,1,10) from cal_events where title not in ($import_exclude) ;" > $ramdisk/lightning_entries

# missglückter versuch
#sqlite3 -separator '","' $lighning_db "select title,\"\`date -d @\"||substr(event_start,1,10)||\" +%Y-%m-%d\`\", replace(cal_properties.value,'',''''), $zones from cal_events, cal_properties where cal_events.id=cal_properties.item_id and cal_events.cal_id=cal_properties.cal_id and cal_properties.key='DESCRIPTION';" > $ramdisk/lightning_entries

#diff $ramdisk/lightning_entries $cached_files/lightning_entries_last > $cached_files/lightning_entries

cp $ramdisk/lightning_entries $cached_files/lightning_entries
diff <(sort $cached_files"/lightning_entries" ) <(sort $cached_files"/lightning_entries_last") > $ramdisk/lightning_entries


# $EDITOR "$cached_files/lightning_entries" #Einträge zur Kontrolle vor import öffnen

grep -e '^< ' $ramdisk/lightning_entries >  $ramdisk/lightning_entries_toadd
sed -i 's/< //g' $ramdisk/lightning_entries_toadd

$EDITOR "$ramdisk/lightning_entries_toadd" #Einträge zur Kontrolle vor import öffnen

echo "adding entries..."
echo ""

while read line
do

	#echo "insert into links (name,source,date,zone,pid,fid) values (\"$line\");"
	#max_id=`sqlite3 $database "select max(id) from infos;"`

	next_id=`sqlite3 $database "select coalesce ( (select id from infos where name='' order by id limit 1),(select max(id)+1 from infos) ); "`

	sqlite3 $database "delete from infos where id=$next_id; "


	title=`echo $line | cut -f1 -d','` 
	dateAdded_unixtime=`echo $line | cut -f2 -d','`
	dateAdded=`date -d "@$dateAdded_unixtime" "+%Y-%m-%d %H:%M:%S" | sed "s/ 00:00:00//g"`
	expiration_unixtime=`echo $line | cut -f4 -d','`
	expiration=`date -d "@$expiration_unixtime" "+%Y-%m-%d %H:%M:%S" | sed "s/ 23:59:59//g"`
	fid=`echo $line | cut -f3 -d','`

	text=`sqlite3 -separator '","' $lighning_db "select replace(cal_properties.value,'','''') from cal_events, cal_properties where cal_events.id=cal_properties.item_id and cal_events.cal_id=cal_properties.cal_id and cal_properties.key='DESCRIPTION' and cal_properties.item_id=\"$fid\";"`
	text="'$text'"

	echo $fid
	echo Description: $text
	echo ""

	#echo fid: "$fid"
	echo Adding "$title"
	sqlite3 $database "insert into infos (name,dateAdded,text,zone,expiration,exp_action) values (\"$title\",\"$dateAdded\",$text,\"$zones\",\"$expiration\",$exp_action);"
	#sqlite3 $database "update links set dateAdded=`date -d @ dateAdded`


	category_name=`sqlite3 $lighning_db "select value from cal_properties where cal_properties.key='CATEGORIES' and cal_properties.item_id=\"$fid\";"`
	#echo category_name: $category_name
	echo ""
	echo "Insert $title in $category_name"
	sqlite3 $database "insert into category_item (category_id,item_id,item_type_id) values ((select id from category where name=\"$category_name\" union select category.id from category, category_alias where category.id=category_alias.category_id and category_alias.name=\"$category_name\"),$next_id,1);" 2>> $ramdisk/errorlog

done < $ramdisk/lightning_entries_toadd



