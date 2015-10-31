#!/bin/bash
# Skript: autoinit_own.sh

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10


source ${0%/*}/config

msearch_opt_args="-pkr40"  #example "-v"
echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[96m Tips: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
if [ -e $ramdisk/category/tips ] ; then # test -e /mnt/... ; then
	POSITION=$[ ( $RANDOM % `msearch $msearch_opt_args -ci -x "done" tips ` )  ]
	msearch $msearch_opt_args -i -o1 -t$POSITION -x "done" tips 
fi

echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[96m Citation: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
if [ -e $ramdisk/category/citation ] ; then # test -e /mnt/... ; then
	POSITION=$[ ( $RANDOM % `msearch $msearch_opt_args -ci -x "done" citation ` )  ]
	msearch $msearch_opt_args -i -o1 -t$POSITION -x "done" citation 

	#adding pub_dbs
for i in 8 9 10; do
	cp $infosystem/template.db $infosystem/pub_dbs/infosystem_$i.db #begin with initial database
	sqlite3 -header -csv $database "select * from infos where zone in (select zone from zones where zones.zones=$i);" > $ramdisk/infosystem_$i.dump
 sqlite3 -header -csv $infosystem/pub_dbs/infosystem_$i.db ".import $ramdisk/infosystem_$i.dump infos" 2> /dev/null
 sqlite3 -header -csv $database "select * from links where zone in (select zone from zones where zones.zones=$i);" > $ramdisk/infosystem_$i.dump
 sqlite3 -header -csv $infosystem/pub_dbs/infosystem_$i.db ".import $ramdisk/infosystem_$i.dump links" 2> /dev/null
 sqlite3 -header -csv $database "select * from category_item where ((item_type_id=1 and item_id in (select id from infos where zone in (select zone from zones where zones.zones=$i)) or (item_type_id=2 and item_id in (select id from links where zone in (select zone from zones where zones.zones=$i)))));" > $ramdisk/infosystem_$i.dump
 sqlite3 -header -csv $infosystem/pub_dbs/infosystem_$i.db ".import $ramdisk/infosystem_$i.dump category_item" 2> /dev/null
 sqlite3 -header -csv $database "select * from category where zone in (select zone from zones where zones.zones=$i);" > $ramdisk/infosystem_$i.dump
 sqlite3 -header -csv $infosystem/pub_dbs/infosystem_$i.db ".import $ramdisk/infosystem_$i.dump category" 2> /dev/null

 #maybe also adding item_ref later
done

#then you have to choose where you want upload your public db's
# scp /pub_dbs/infosystem_8.db public@server:html
# scp /pub_dbs/infosystem_9.db user@your_server:/var/www
# scp /pub_dbs/infosystem_10.db user@server_at_work:

fi

# You can add further searches here
