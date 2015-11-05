#!/bin/bash

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

#usage
#customize_info [name]_id  

source ${0%/*}/config
id=`echo "$1" | awk -F'_' '//{print $NF}'`
choice="n"
echo ""

#alternativ msearch Einbauen - ist aber eher overkill
info_name=`sqlite3 $database "select infos.name || ' [ Date: ' || dateAdded || ' ] ',' [ ' || date || ' ] ', ' [ ' || expiration || ' ] ', ' [ z:' || zone || ' ] ' from infos where id=$id and infos.zone in (select zone from zones where zones.zones=$zones);"`

if [[ $info_name == "" ]] ; then
	exit $EXIT_SUCCESS
else
	echo -e "Infoname: \E[32m$info_name "; tput sgr0
	echo ""
fi

while true 
do

	read -n 1 -p "Customize information? (n=name f=file-ref l=link-ref i=info-ref d=set-date a=add-time-period r=rating o=occurrence-date e=expire c=expiration_category t=auto-terminate z=zone h=help [other_key]=nothing) " choice #

	if [[ $choice == "r" ]] ; then 

		sqlite3 -header $database "select distinct infos.rating, infos.votes, infos.name from infos where id=$id and infos.zone in (select zone from zones where zones.zones=$zones);"

		#category_match>=$# nur nach getargs
		#substr(infos.text,0,40) #evtl einbauen

		echo ""
		echo ""

		read -p "Rating: " rating

		sqlite3 $database "update infos set rating=$rating where id=$id;"
		echo ""


		read -p "Votes: " votes

		sqlite3 $database "update infos set votes=$votes where id=$id;"

		echo ""
		echo ""
		sqlite3 -header $database "select distinct infos.rating, infos.votes, infos.name from infos where id=$id and infos.zone in (select zone from zones where zones.zones=$zones);"


	elif [[ $choice == "n" ]] ; then
		echo ""
		echo "old name: $info_name"
		echo ""
		read -p "Enter new name: " set_name
		echo "set_name=$set_name"
		sqlite3 $database "update infos set name='$set_name' where id=$id;"


	elif [[ $choice == "f" ]] ; then

		#	msearch -f `echo $category | sed "s/,/ /g" | sed "s/'//g"`
		POSITION=0
		INK=5
		while [[ $choice != n ]] 
		do

			sqlite3 -header $database "select distinct id, files.name from files, category_files where files.id=category_files.item_id and category_files.category_id in (select category_id from category_info where item_id=$id)  and files.zone in (select zone from zones where zones.zones=$zones) LIMIT $INK OFFSET $POSITION;"
			echo ""
			echo ""
			read -n 1 -p "Proceed? (Y/n)" choice #

			if [[ $choice = n ]] ; then
				echo "" 
			fi
			POSITION=`expr $POSITION + $INK`

		done

		read -p "Enter id of the file: " file_id #
		echo ""
		sqlite3 $database "insert into item_ref (item1_id, item1_type_id, item2_id, item2_type_id) values ($id, 1, $file_id, 3);"
		#sqlite3 $database "update infos set used_in=$file_id where id=(select max(id) from infos);"
		#sqlite3 $database "update infos set used_in_type=3 where id=(select max(id) from infos);"

	elif [[ $choice == "l" ]] ; then 
		echo ""
		echo ""
		
		#	msearch -bl -n1 `echo $category | sed "s/,/ /g" | sed "s/'//g"`
		#	loop 5 "

		category=`sqlite3 $database "select distinct category.name from infos, category, category_info where infos.id=$id and category_info.item_id=infos.id and category_info.category_id=category.id and category.zone in (select zone from zones where zones.zones=$zones) order by category.name;"`
	  echo category: $category	
		msearch -kpql -n1 -b $category | grep 'ID='

		#old version without msearch
		#POSITION=0
		#INK=5
		#while [[ $choice != n ]] 
		#do

		#	sqlite3 -header $database "select distinct id, links.name from links, category_link where links.id=category_link.item_id and category_link.category_id in (select category_id from category_info where item_id=$id)  and links.zone in (select zone from zones where zones.zones=$zones) LIMIT $INK OFFSET $POSITION;"
#			echo ""
#			echo ""
#			read -n 1 -p "Proceed? (Y/n)" choice #

#			if [[ $choice = n ]] ; then
#				echo ""
#			fi
#			POSITION=`expr $POSITION + $INK`

#		done
		echo ""	
		read -p "Enter id of the link: " link_id
		echo ""
		#	echo "insert into item_ref (item1_id, item1_type_id, item2_id, item2_type_id) values ((select max(id) from infos), 1, $link_id, 2);"
		sqlite3 $database "insert into item_ref (item1_id, item1_type_id, item2_id, item2_type_id) values ($id, 1, $link_id, 2);"
		#sqlite3 $database "update infos set used_in=$link_id where id=(select max(id) from infos);"
		#sqlite3 $database "update infos set used_in_type=3 where id=(select max(id) from infos);"


	elif [[ $choice == "i" ]] ; then 
		echo ""
		echo ""

		POSITION=0
		INK=5
		while [[ $choice != n ]] 
		do

			sqlite3 -header $database "select distinct id, infos.name from infos, category_info where infos.id=category_info.item_id and category_info.category_id in (select category_id from category_info where item_id=$id) and id!=$id and infos.zone in (select zone from zones where zones.zones=$zones) LIMIT $INK OFFSET $POSITION;"
			echo ""
			echo ""
			read -n 1 -p "Proceed? (Y/n)" choice #

			if [[ $choice = n ]] ; then
				echo ""
			fi
			POSITION=`expr $POSITION + $INK`

		done
		echo ""	
		read -p "Enter id of the info: " info_id
		echo ""
		sqlite3 $database "insert into item_ref (item1_id, item1_type_id, item2_id, item2_type_id) values ($id, 1, $info_id, 1);"


	elif [[ $choice == "d" ]] ; then
		echo ""
		echo ""
		read -p "Enter date (YYYY-MM-DD hh:mm:ss): " set_date
		#set_date=`echo "$infoname" | cut -f1 -d'_'`
		echo "set_date=$set_date"
		sqlite3 $database "update infos set dateAdded='$set_date' where id=$id;"
		sqlite3 $database "update infos set date='$set_date' where id=$id;"
		#rm_tag_info $id "done";
		#Set expiration date - especially for time schedule
	elif [[ $choice == "e" ]] ; then
		echo ""
		echo ""
		read -p "Enter expiration date (YYYY-MM-DD hh:mm:ss): " exp_date
		#exp_date=`echo "$infoname" | cut -f2 -d'_'`
		sqlite3 $database "update infos set expiration='$exp_date' where id=$id;"
		echo "exp_date=$exp_date"
		sqlite3 $database "update infos set exp_action=10 where id=$id;"
		rm_tag_info $id "done";

	elif [[ $choice == "o" ]] ; then
		echo ""
		echo ""
		read -p "Enter date (YYYY-MM-DD hh:mm:ss): " set_date
		#set_date=`echo "$infoname" | cut -f1 -d'_'`
		echo "set_date=$set_date"
		sqlite3 $database "update infos set date='$set_date' where id=$id;"
		rm_tag_info $id "done";
		#Set expiration date - especially for time schedule

	elif [[ $choice == "c" ]] ; then
		echo ""
		echo ""
		read -p "Enter category to set after expiration: " exp_category
		#exp_date=`echo "$infoname" | cut -f2 -d'_'`
		sqlite3 $database "update infos set exp_action=(select id from category where name='$exp_category') where id=$id;"
		rm_tag_info $id "done";

	elif [[ $choice == "t" ]] ; then
		echo ""
		echo ""
		echo "info will be deleted after expiration date!"
		echo ""
		sqlite3 $database "update infos set exp_action=0 where id=$id;"

	elif [[ $choice == "a" ]] ; then
		echo ""
		echo ""
		read -p "Enter time period (days, weeks, month) : " time_to_add
		sqlite3 $database "update infos set date=DateTime(Date,'$time_to_add') where id=$id;"
		sqlite3 $database "select date from infos where id=$id;"
		sqlite3 $database "update infos set expiration=DateTime(expiration,'$time_to_add') where id=$id;"
		sqlite3 $database "select expiration from infos where id=$id;"

	elif [[ $choice == "z" ]] ; then
		echo ""
		echo ""
		read -p "Enter new zone (1=private,2=work,3=both [+4 protected, +8 public] ): " set_zone
		sqlite3 $database "update infos set zone='$set_zone' where id=$id;"


	elif [[ $choice == "h" ]] ; then
		echo ""
		echo ""
		echo "f		connect item with file"
		echo "l		connect item with link"
		echo "i   connect item with other info"
		echo "d		set date of the item YYYY-MM-DD hh:mm:ss"
		echo "o		set occurrence date YYYY-MM-DD hh:mm:ss"
		echo "r		set rating of the item"
		echo "e		set date when item expires YYYY-MM-DD hh:mm:ss"
		echo "t		info will be deleted after expiration date!"
		echo "a		add period of time (also negative possible)"
		echo "h		show this help contents"
		echo "z   set zone of the item"
		echo ""
		echo ""



	else
		exit $EXIT_SUCCESS

	fi

done

exit $EXIT_SUCCESS

