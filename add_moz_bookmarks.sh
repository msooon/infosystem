#!/bin/bash

#usage
#add_moz_bookmarks.sh

source ${0%/*}/config

cd /category

if [ ! -f $cached_files/$pid"_time" ];
then
	echo "0" > $cached_files/$pid"_time"
fi

read -n 1 -p "view/edit config before? (Y/n) " choice
if [[ $choice == "n" ]] ; then
	echo ""
	echo "existing config will be used"
else
	$EDITOR ${0%/*}/config
	source ${0%/*}/config
fi
echo ""

# welche Ordner sind nicht vorhanden?
#prod sqlite3 $ffox_profile/places.sqlite "select distinct lower(tag.title) from moz_bookmarks as tag, moz_bookmarks as tag_link, moz_places where moz_places.id=tag_link.fk and tag_link.parent=tag.id and tag.type=2;" > $ramdisk/moz_bookmarks_folder

#sqlite3 $database "select lower(name) from category where zone in (select zone from zones where zones.zones=$zones)
#             UNION select name from category_alias where category_id in (select id from category where zone in (select zone from zones where zones.zones=$zones));" > $ramdisk/database_categorys

#prod sqlite3 $database "select lower(name) from category 
#prod						 UNION select lower(name) from category_alias;" > $ramdisk/database_categorys

#prod echo "Missing categories in Infosystem"
#prod diff -i <(sort "$ramdisk/database_categorys" ) <(sort "$ramdisk/moz_bookmarks_folder") | grep '>'

read -n 1 -p "Use diff for update? (Y/n) " choice
if [[ $choice == "n" ]] ; then
	echo ""
	pid_time=`cat  $cached_files/$pid"_time"`
	diff_update=0
else
	pid_time=0
	diff_update=1
fi

echo "pid_time: $pid_time"

# version to avoid problems
touch $cached_files/$pid"_moz_bookmarks" # needed if file not exists

#Better way would be to rebuild the cache from Infosystem-DB

#if [ -e "$cached_files/$pid\"_moz_bookmarks\"" ] ; then
#echo "cached file found"
#echo ""
#else

#fids=`sqlite3 $database "select fid || ',' from links where pid=$pid;"`
#fids=$fids"0" #only a number not used after komma, I was to lazy to remove it

#sqlite3 -separator ',' $ffox_profile/places.sqlite "select replace(replace(replace(moz_bookmarks.title,'\"',' '),',',' '),'|',' '), replace(replace(replace(replace(moz_places.url,'*',''),'\"',' '),',',' '),'|',' '), CAST(substr(moz_bookmarks.dateAdded,1,10) as integer) used_date, moz_places.id, moz_bookmarks.type from moz_bookmarks, moz_places, moz_bookmarks as parent where moz_bookmarks.type=1 and moz_bookmarks.id>127 and moz_bookmarks.fk=moz_places.id and moz_bookmarks.parent=parent.id and parent.parent!=4 and used_date>$pid_time and moz_places.id in ($fids);" > $cached_files/$pid"_moz_bookmarks"	
#sqlite3 -separator ',' $database "select name, source, fid where fid in ($fids);" >> $cached_files/$pid"_moz_bookmarks"
#fi

mv $cached_files/$pid"_moz_bookmarks" $cached_files/$pid"_moz_bookmarks_last"

#2013-04-24 msoon exclude * because of rarely problems
sqlite3 -separator ',' $ffox_profile/places.sqlite "select replace(replace(replace(replace(moz_bookmarks.title,'\"',' '),',',' '),'|',' '),'*',' '), replace(replace(replace(replace(moz_places.url,'*',''),'\"',' '),',',' '),'|',' '), CAST(substr(moz_bookmarks.dateAdded,1,10) as integer) used_date, moz_places.id, moz_bookmarks.type from moz_bookmarks, moz_places, moz_bookmarks as parent where moz_bookmarks.type=1 and moz_bookmarks.id>127 and moz_bookmarks.fk=moz_places.id and moz_bookmarks.parent=parent.id and parent.parent!=4 and used_date>$pid_time;" > $ramdisk/moz_bookmarks # replaced characters: " , | 

date +%s > $cached_files/$pid"_time"


if [[ $diff_update = 1 ]] ; then
	cp $ramdisk/moz_bookmarks $cached_files/$pid"_moz_bookmarks"	
	diff <(sort $cached_files/$pid"_moz_bookmarks" ) <(sort $cached_files/$pid"_moz_bookmarks_last") > $ramdisk/moz_bookmarks         
	grep -e '^> ' $ramdisk/moz_bookmarks >  $ramdisk/moz_bookmarks_todel
	sed -i 's/> //g' $ramdisk/moz_bookmarks_todel
	sed -i 's/@ / /g' $ramdisk/moz_bookmarks_todel
	$EDITOR "$ramdisk/moz_bookmarks_todel" #Bookmarks zur Kontrolle vor import öffnen

	grep -e '^< ' $ramdisk/moz_bookmarks >  $ramdisk/moz_bookmarks_toadd
	sed -i 's/< //g' $ramdisk/moz_bookmarks_toadd
	sed -i 's/@/ /g' $ramdisk/moz_bookmarks_toadd
	$EDITOR "$ramdisk/moz_bookmarks_toadd" #Bookmarks zur Kontrolle vor import öffnen

	echo ""
	echo "removing links from infosystem"
	echo ""

	while read line
	do

		fid=`echo $line | cut -f4 -d','`
		id=`sqlite3 $database "select id from links where fid=$fid ;"`

		rm_link $id >> /dev/null

		echo "id: $id - fid: $fid"

	done < $ramdisk/moz_bookmarks_todel

else

	$EDITOR "$ramdisk/moz_bookmarks" #Bookmarks zur Kontrolle vor import öffnen
	mv "$ramdisk/moz_bookmarks" "$ramdisk/moz_bookmarks_toadd"
fi

echo ""
echo "adding links to infosystem"
echo ""

while read line
do

	title=`echo $line | cut -f1 -d','`
	url=`echo $line | cut -f2 -d','`
	dateAdded_unixtime=`echo $line | cut -f3 -d','`
	dateAdded=`date -d @$dateAdded_unixtime +%Y-%m-%d`
	#text=`echo $line | cut -f3 -d','`
	fid=`echo $line | cut -f4 -d','`

	next_id=`sqlite3 $database "select coalesce ( (select id from links where name='' order by id limit 1),(select max(id)+1 from links) ); "`

	sqlite3 $database "delete from links where id=$next_id; "

	sqlite3 $database "insert into links (id,name,source,dateAdded,zone,pid,fid) values (\"$next_id\",\"$title\",\"$url\",\"$dateAdded\",\"$zones\",\"$pid\",\"$fid\");" 2>> $ramdisk/errorlog

	echo "id: $next_id - fid: $fid"

	# Ordner und Tags werden verwendet
	sqlite3 -separator '","' $ffox_profile/places.sqlite "select tag.title from moz_bookmarks as tag, moz_bookmarks as tag_link, moz_places where moz_places.id=tag_link.fk and tag_link.parent=tag.id and tag.type=2 and moz_places.id=$fid;" > $ramdisk/moz_bookmarks_folder

	category_name="`cat $ramdisk/moz_bookmarks_folder`"
	#Anmerkung: Kategorien sind in mehreren Zeilen gespeichert funktioniert zwar - aber könnte evtl sauberer gelöst werden

	#needed if link allready exists in infosystem
	id=`sqlite3 $database "select id from links where fid=$fid; "`

	tag_link $id $category_name
done < $ramdisk/moz_bookmarks_toadd

