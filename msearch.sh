#!/bin/bash

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=
EXIT_BUG=10


# Aktuelles Verzeichniss ausgeben hilft nicht bei symlinks aus /usr/local/bin
#echo `dirname $0`
#echo ${0%/*}

source ${0%/*}/config 2> /dev/null 
source /media/daten/infosystem/config #benötigt für loop #TODO absoluter Pfad beseitigen

# Variablen für Optionsschalter hier mit Default-Werten vorbelegen
#VERBOSE=n #now in global config
OPTFILE=""
file_search=""
info_search=""
link_search=""
search_pattern=""
item_id=""
use_google=""
use_IMDB=""
show_only=""
grep_only=""
#min_catagorys="" #default: items müssen in allen Kategorien sein absolete!
min_catagorys=""
categories="''"
ex_category="''"
offset=""
item_type_to_search=0 #default: infos, links und files werden gesucht - vorsicht id für files hier 4!
parameters="" #for history
sort_order="category_match desc, rating desc, date desc" #Standard: Bestbewerteste und neueste zuerst
hits_before_asking=4 #Ask for proceeding if there are more than defined hits
search_date=""
USE_HISTORY=y
Q_MODE=n
used_layers=3 #sub categories - since sqlite 3.8 you need compile flag YYSTACKDEPTH=<max_depth> e.g 101 if you reach the limit
category_next_layer=""
category_layers=""
KEEP_RESULTS=n
EXCERPT=n
INDEMNIFY="" #indemnify some categories
INDEMNIFY_COUNT=0
ADDITIONAL_DB=""

# Funktionen
function usage 
{
	echo "Usage: $SCRIPTNAME [-h] [-v] [-i|-l|-f] [-o hits] [-n num_of_categorys] [-x category_to_exclude] [other options] [-s searchpattern] [-t offset] [categories]" >&2
	echo ""
	echo "-g	use google"
	echo "-m	use IMDB (needs parameter s)"	
	echo "-x	one category_to_exclude e.g. cat1 or more \"cat1','cat2','cat3\""
	echo "-c	count hits - default files if -i or -l not choosen"
	echo "-e	search in e-mails and other text-files"
	echo "-u	unsharp-search ü,ä,ö,ß"
	echo "-d	search since or before or exact date e.g. \">'2010-06-15'\" " #not good looking but flexible :-)
	echo "-p	prevent writing history"
	echo "-q	q-mode only output item title's (usable for questions)"
	echo "-w	aditional where-part"
	echo "-k	keep results"
	echo "-r	only excerpt of infotext"
	echo ""
	[[ $# -eq 1 ]] && exit $1 || exit $EXIT_FAILURE
}


# f(0) = c or parent in (c)
# f(1) = or parent in ( l in (f(0)))
# f(n) = or parent in ( l in (f(n-1)))

category_search()  
{       
	if [[ $1 = 0 ]] ; then 
		echo "($category_id)"
		return 0
	else 
		echo -n "
		(
		$category_next_layer in 
		
		"
		category_search $[$1-1]
		echo "
		)"
	fi
}

#save args for later
ALL_ARGS=$@

ALL_ARGS_FIX=''

for i in "$@"; do 
#	# echo ALL_ARGS="$ALL_ARGS"
	ALL_ARGS_FIX="$ALL_ARGS_FIX \"${i//\"/\\\"}\""
done

#Parse paremeter
while getopts 'bs:d:o:n:x:r:t:w:y:z:eiflgamopcvuqkh' OPTION ; do
	case $OPTION in
		a) #reseverd for audio output
			 echo using some software to read information texts
			 ;;
		b)      #Breadcrump Mode
			#TODO -b saubere Lösung mit args_without_b ohne sed und mit Parameter -d ermöglichen
			args_without_b=`echo "$@" | sed "s/-b/-/g"  | sed "s/- / /g" | sed "s/--/-/g"` 
			database= #prevent access of running script 
			loop 2 "msearch -p -oINK -tPOSITION $args_without_b"
			show_only=" limit 0 " #to break up other msearch
			parameters="$parameters""b" #for history
			exit $EXIT_SUCCESS
			;;
		c)	count_hits=1
			parameters="$parameters""c" #for history
			;;
		d) #     search_date=" and (substr(date,1,11)$OPTARG or substr(lastModified,1,11)$OPTARG)" # format YYYY-MM-DD e.g. >'2010-09-15'
			search_date=" and (Date(date)$OPTARG OR Date(dateAdded)$OPTARG)"  # format YYYY-MM-DD e.g. >'2010-09-15'
			sort_order="category_match desc, date, rating desc"
			#		search_pattern=$OPTARG #TODO eigenes Feld damit Kombination mit s funktioniert
			parameters="$parameters""d" #for history
			;;
		s)        #TODO bei umstieg auf PSQL umgehen das like kontextsensitiv sucht
			file_search="and ((files.name like '%""$OPTARG""%') or (files.id like '%""$OPTARG""%'))" 
			info_search="and ((infos.name like '%""$OPTARG""%') or (infos.text like '%""$OPTARG""%') or (infos.id like '%""$OPTARG""%'))"
			link_search="and ((links.name like '%""$OPTARG""%') or (links.source like '%""$OPTARG""%') or (links.id like '%""$OPTARG""%'))"
			search_pattern=$OPTARG
			parameters="$parameters""s" #for history
			;;
		e)      use_email=1
			parameters="$parameters""e" #for history
			;;
		g)	use_google=1
			parameters="$parameters""g" #for history
			;;
		h)        usage $EXIT_SUCCESS
			;;
		i)       item_type_to_search=`echo "$item_type_to_search+1" | bc` 
			parameters="$parameters""i" #for history
			;;
		f)       item_type_to_search=`echo "$item_type_to_search+4" | bc` 
			parameters="$parameters""f" #for history 
			;;
		l)       item_type_to_search=`echo "$item_type_to_search+2" | bc`
			parameters="$parameters""l" #for history
			;;
		o)      # show only specified number of hits
			show_only=" limit $OPTARG "
			grep_only=" -m$OPTARG"
			parameters="$parameters""o$OPTARG" #for history
			;;
		p)      USE_HISTORY=n 
			;;
		q)    	# maybe for quantity
						Q_MODE=y		#Quite-Mode or Qestion-Mode
						parameters="$parameters""q" #for history
			      ;;
		r)      EXCERPT=y    #
						EXCERPT_LINES=$OPTARG
			            parameters="$parameters""r$OPTARG" #for history
									            ;;
		m)	use_IMDB=1
			parameters="$parameters""m" #for history
			;;
		x)      ex_category="'$OPTARG'"
			parameters="$parameters""x" #for history
			;;
		t)      #only in combination with parameter 'o' (LIMIT)
			offset="OFFSET $OPTARG"
			parameters="$parameters""t$OPTARG" #for history
			;;
		u)      #benötigt option s
			search_pattern_u=`echo $search_pattern | sed "s/ö/oe/g" | sed "s/ä/ae/g" | sed "s/ü/ue/g" | sed "s/ß/ss/g"`
			file_search="and ((files.name like '%""$search_pattern""%') or (files.name like '%""$search_pattern_u""%'))"
			info_search="and ((infos.name like '%""$search_pattern""%') or (infos.text like '%""$search_pattern""%') or (infos.name like '%""$search_pattern_u""%') or (infos.text like '%""$search_pattern_u""%'))"
			link_search="and ((links.name like '%""$search_pattern""%') or (links.name like '%""$search_pattern_u""%'))"
			parameters="$parameters""u" #for history
			;;
		v) VERBOSE=y
			parameters="$parameters""v" #for history
			;;
			#2012-05-21 auch lastModified und nur nach infos und links wird gesucht
		w)
			WHERE_PART=" AND $OPTARG"
			parameters="$parameters""w$OPTARG" #for history
			;;

		k)
			KEEP_RESULTS=y
			parameters="$parameters""k" #for history
			;;
		
#		j)
		n)	min_catagorys="*0+$OPTARG"
			#min_catagorys="$OPTARG"
			parameters="$parameters""c$min_catagorys" #for history
			;;
		y) #TODO 
			 #indemnify some categories in combination with n
			 INDEMNIFY_COUNT="$OPTARG"
			 INDEMNIFY=" AND id in "
			 parameters="$parameters""y$OPTARG" #for history
			 ;;
		z) #other db zusatz
				ADDITIONAL_DB=y
				database=$OPTARG
			 ;;
		\?)        echo "Unbekannte Option \"-$OPTARG\"." >&2
			usage $EXIT_ERROR
			;;
		:)        echo "Option \"-$OPTARG\" benötigt ein Argument." >&2
			usage $EXIT_ERROR
			;;
		*)        echo "Dies kann eigentlich gar nicht passiert sein..."
			>&2
			usage $EXIT_BUG
			;;
	esac
done



j=0
# Verbrauchte Argumente überspringen
shift $(( OPTIND - 1 ))

# Eventuelle Tests auf min./max. Anzahl Argumente hier
if (( $# < 1 )) ; then
	#echo "All infos in zone $zones:"
	echo ""
else
	# Kategorien auswählen
	for ARG ; do
		if [[ $VERBOSE = y ]] ; then
			echo -n "Argument: $ARG"
			echo ""
		fi

		# Sorry about this part :-)
	  j=$(expr $j + 1) #counter for layer

		one_category="'`basename $ARG`'"
		
		#needed for history
		categories="$categories,$one_category"
		category_id=`sqlite3 "$database" "select id from category where (lower(category.name)=lower($one_category) or category.id in (select distinct category_id from category_alias where lower(name)=lower($one_category)));"`
		#category_id="select id from category where (lower(category.name)=lower($one_category) or category.id in (select distinct category_id from category_alias where lower(name)=lower($one_category)))"

		category_next_layer="select id from category where parent"

		#the category layer will be saved in array because they are needed later in sub-items
		category_layers[$j]="select id from category where (id in ($category_id) 
		or parent in 
		($category_id)"
		for ((i=1; i < $used_layers; i++)) ; do
			#echo category_layers: "$category_layers"
				category_layers[$j]="${category_layers[$j]} 
				or parent in"
				category_layers[$j]="${category_layers[$j]} `category_search $i`"
		done
		category_layers[$j]="${category_layers[$j]} ) and category.zone in (select zone from zones where zones.zones=$zones)"
		if [[ $VERBOSE = y ]] ; then
#			echo "category_layers $j: ${category_layers[$j]}"
			echo -e "\E[35mcategories: `sqlite3 \"$database\" \"select name from category where id in (${category_layers[$j]});\"`"; tput sgr0
		fi
		
	done
	categories=`echo $categories | sed "s/^'',//g"`
fi

if [[ $VERBOSE = y ]] ; then
	echo ""
	echo auto_update: $auto_update        
fi

# if auto update in config set then update items in database
if [[ $auto_update == 1 ]] ; then
	update_infos
	update_files
fi

if [[ $USE_HISTORY = y ]] ; then
	if [[ $VERBOSE = y ]] ; then
		echo ""
		echo "Adding entry to history: "
		echo "insert into history (search_term,categories,ex_categories,zones,timestamp,command,parameters) values ('$search_pattern',`echo $categories | sed "s/','/,/g"`,`echo $ex_category | sed "s/','/,/g"`,$zones,(select datetime()),'$SCRIPTNAME','$parameters');"
		echo ""
	fi

	sqlite3 $database "insert into history (search_term,categories,ex_categories,zones,timestamp,command,parameters) values ('$search_pattern',`echo $categories | sed "s/','/,/g"`,`echo $ex_category | sed "s/','/,/g"`,$zones,(select datetime()),'$SCRIPTNAME','$parameters');"
	#	echo ""

fi

if [[ $VERBOSE = y ]] ; then
	echo "item_type_to_search: $item_type_to_search"
fi

###############################
# Files
###############################

item_types=( 0 4 5 6 7 )

for i in ${item_types[@]}
do
	if [ $i == $item_type_to_search ] ; then

			categories_clause=""

		if [[ $categories != "''" ]] ; then

			for ((j=1; j <= $#; j++)) ; do 
				if [ $j -gt 1 ] ; then	
					categories_clause=" $categories_clause UNION ALL"
				fi
				categories_clause="$categories_clause select v_files.id, v_files.inode, v_files.name, v_files.source, v_files.rating, v_files.zone, v_files.disksource , v_files.binode  from v_files where v_files.id in 
				(
				select item_id from category_file, category where category_file.category_id=category.id AND category.id in
					(
					${category_layers[$j]}
					) 
					)"
				done
				categories_clause="($categories_clause) as files"
			else
				categories_clause="v_files as files"
			fi


		#20111009 Es werden keine backups mehr gesucht
		 dbquery="select files.id, files.inode, files.name, files.disksource, count(*) as category_match, files.rating from $categories_clause where 1=1 $file_search $ex_category_clause $search_date $WHERE_PART and (files.binode=0 or files.binode is null) and files.zone in (select zone from zones where zones.zones=$zones)
		group by files.id having category_match>=$# $min_catagorys order by rating desc $show_only $offset" #TODO evtl date hinzufügen und $sort_order verwenden
		
		hits=`sqlite3 $database "select count(*) from ($dbquery) ;"`
	
		if [[ $count_hits == 1 ]] ; then
			echo $hits
			exit $EXIT_SUCCESS
		fi

		if [ $hits -gt $hits_before_asking ] ; then

			read -s -n 1 -p "There are $hits files to show: proceed (Y/n)? " choice
			echo ""

			case "$choice" in
				n|N)	exit $EXIT_SUCCESS	;;
				Y|y|"")	true	;;
			esac
		fi

		if [[ $ex_category != "''" ]] ; then
			ex_category_clause="and files.id not in (select distinct files.id from files, category, category_item where category_item.item_type_id=3 and category_item.category_id=category.id and category_item.item_id=files.id and (category.name in ($ex_category) or category.id in (select distinct category_id from category_alias where name in ($ex_category))) and category.zone in (select zone from zones where zones.zones=$zones)) "
			if [[ $VERBOSE = y ]] ; then
				echo "ex_category_clause: $ex_category_clause"
			fi
		fi

		if [[ $VERBOSE = y ]] ; then
		  echo hits_before_asking: $hits_before_asking
			echo ""
			echo "FILE - SELECT"
			date +%H:%M:%S:%N
			echo "$dbquery ;"
		fi

		sqlite3 $database "$dbquery ;" > $ramdisk/temp_files

		if [[ $VERBOSE = y ]] ; then
			date +%H:%M:%S:%N
		fi

		mkdir $ramdisk/files 2> /dev/null
		if [[ $KEEP_RESULTS = n ]] ; then
			rm -r $ramdisk/files/* 2> /dev/null
		fi

		#symlinks für gefundene Dateien anlegen
		while read line
		do
			#echo ""
			inode=`echo "$line" | cut -f2 -d'|'`
			filename=`echo "$line" | cut -f1,3 -d'|' | sed "s/|/_/g"`
			id=`echo "$line" | cut -f1 -d'|'`
			rating="`echo "$line" | cut -f6 -d'|'`"
			cmatch=`echo "$line" | cut -f3 -d'|'`

			echo -e "\E[33m$filename `if [[ $min_catagorys > 0 ]] ; then echo cm:$cmatch; fi` (rating:$rating)"; tput sgr0

			if [[ $VERBOSE = y ]] ; then
				echo "Backups: "
				sqlite3 -header $database "select distinct files.id, files.inode, files.name, files.disksource from files where 1=1 and files.binode=$id and files.zone in (select zone from zones where zones.zones=$zones);"
			fi

			#  sqlite3 $database "select distinct inode, name, disksource from files where id in (select backup from files where id=$id);" | xargs echo "Backup von: "

			id=`echo "$line" | cut -f1 -d'|'`
			sqlite3 $database "select distinct category.name from files, category, category_item where files.id=$id and category_item.item_type_id=3 and category_item.item_id=files.id and category_item.category_id=category.id and category.zone in (select zone from zones where zones.zones=$zones) order by category.name;" | xargs echo Kategorien:

			if [[ $USE_HISTORY = y ]] ; then
				sqlite3 $database "insert into history (item_id,item_type_id,search_term,categories,ex_categories,zones,timestamp,command,parameters) values ($id,3,'$search_pattern',`echo $categories | sed "s/','/,/g"`,`echo $ex_category | sed "s/','/,/g"`,$zones,(select datetime()),'$SCRIPTNAME','$parameters');"
			fi

			# Symlinks only created if disk available
			disksource=`echo "$line" | cut -f4 -d'|'`
			if [ -e /mnt/$disksource/.diskinfo ] ; then # test -e /mnt/hd5/.diskinfo ; then
				ln -s "`find /mnt/$disksource/ -inum $inode 2> /dev/null`" "$ramdisk/files/$filename"
				echo "symlink created [OK]";
			else
				echo "$filename on $disksource (not connected) -> trying to find backup..."

				backup=`sqlite3 $database "select distinct files.id, files.inode, files.name, files.disksource from files where 1=1 and files.binode=$inode and files.bdisksource='$disksource' and files.zone in (select zone from zones where zones.zones=$zones);"` #> $ramdisk/backups
				#while read line # while verschachteln klappt nicht #TODO mehrere backups checken 
				#do
				backup_inode=`echo $backup | cut -f2 -d'|'`
				backup_filename=`echo $backup | cut -f1,3 -d'|' | sed "s/|/_/g"`
				backup_id=`echo $backup | cut -f1 -d'|'`

				# Symlinks only created if disk available 
				backup_disksource=`echo $backup | cut -f4 -d'|'`
				#echo "backup_disksource: $backup_disksource"
				if [ -e /mnt/$backup_disksource/.diskinfo ] ; then 
					ln -s "`find /mnt/$backup_disksource/ -inum $backup_inode`" "$ramdisk/files/$backup_filename" && echo "symlink $backup_filename  created [OK]"
					
#					&& echo -e "\E[32m symlink fuer backup angelegt";
				else
					echo "no backup found!"
					echo ""
				fi
				#done < $ramdisk/backups
			fi

		done < $ramdisk/temp_files

		#echo ""
		#echo ""

	fi
done


###############################
# Links
###############################

item_types=( 0 2 3 6 7 )
for i in ${item_types[@]}
do
	if [ $i == $item_type_to_search ] ; then

		if [[ $ex_category != "''" ]] ; then
			ex_category_clause="and links.id not in (select distinct links.id from links, category, category_link where category_link.category_id=category.id and category_link.item_id=links.id and (category.name in ($ex_category) or category.id in (select distinct category_id from category_alias where name in ($ex_category))) and category.zone in (select zone from zones where zones.zones=$zones)) "
		fi

			categories_clause=""

		if [[ $categories != "''" ]] ; then

			for ((j=1; j <= $#; j++)) ; do 
				if [ $j -gt 1 ] ; then	
					categories_clause=" $categories_clause UNION ALL"
				fi
				#echo "j: $j"
				categories_clause="$categories_clause select v_links.id, v_links.name, v_links.source, v_links.rating, v_links.zone, DateTime(v_links.date) as date, v_links.mirror,  DateTime(v_links.dateAdded) as dateAdded from v_links where v_links.id in 
				(
				select item_id from category_link, category where category_link.category_id=category.id AND category.id in
					(
					${category_layers[$j]}
					) 
					)"
				done
				categories_clause="($categories_clause) as links"
			else
				categories_clause="v_links as links"

			fi

			dbquery="select links.id, replace(links.name,'/',' '), links.source, count(*) as category_match, links.rating, Date(links.date), links.zone from $categories_clause where 1=1 $link_search $ex_category_clause and (mirror=0 or mirror is null or mirror='') $search_date $WHERE_PART and links.zone in (select zone from zones where zones.zones=$zones)
		group by links.id having category_match>=$# $min_catagorys order by $sort_order $show_only $offset"
	
		hits=`sqlite3 $database "select count(*) from ($dbquery) ;"`
		
		if [[ $count_hits == 1 ]] ; then
			echo $hits
			exit $EXIT_SUCCESS
		fi

		if [[ $VERBOSE = y ]] ; then
		  echo hits_before_asking: $hits_before_asking
			echo "LINK - SELECT"
			date +%H:%M:%S:%N
			echo "$dbquery ;"
		fi

		if [ $hits -gt $hits_before_asking ] ; then

			read -s -n 1 -p "There are $hits links to show: proceed (Y/n)? " choice
			echo ""

			case "$choice" in
				n|N)	exit $EXIT_SUCCESS	;;
				Y|y|"")	true	;;
			esac
		fi

		sqlite3 $database "$dbquery ;" > $ramdisk/temp_links

		if [[ $VERBOSE = y ]] ; then
			date +%H:%M:%S:%N
		fi

		mkdir $ramdisk/links 2> /dev/null
		if [[ $KEEP_RESULTS = n ]] ; then
			rm -r $ramdisk/links/* 2> /dev/null
		fi
		# if [[ $use_clipboard = 1 ]] ; then
		#echo "`head -n1 /mnt/ramdisk/temp_links`" | xclip -selection clipboard
		#fi

		while read line
		do
			#alternative um alle Kategorien anzuzeigen
			id=`echo "$line" | cut -f1 -d'|'`
			linkname=`echo "$line" | cut -f2 -d'|'`
			url=`echo "$line" | cut -f3 -d'|'` # Link
			rating=`echo "$line" | cut -f5 -d'|'`
			date=`echo "$line" | cut -f6 -d'|'`
			cmatch=`echo "$line" | cut -f4 -d'|'`
			zone=`echo "$line" | cut -f7 -d'|'`

			if [[ $ADDITIONAL_DB = y ]] ; then
				echo -e "\E[90m `basename $database`(RO)  \"$linkname\" [ Date: $date ]  (rating:$rating) "; tput sgr0
			else
				echo " (ID=$id)  \"$linkname\" [ Date: $date ] `if [[ $min_catagorys > 0 ]] ; then echo cm:$cmatch; fi`[z:$zone] (rating:$rating) " 
			fi
			echo -e "\E[94m$url"; tput sgr0  #url wird blau ausgegeben  
			echo "$url" > $ramdisk/links/"$id"_"$linkname"

			if [[ $VERBOSE = y ]] ; then
				echo "mirrors: "
				sqlite3 -header $database "select distinct links.id, links.name, links.source, links.rating from links where 1=1 and mirror=$id and links.zone in (select zone from zones where zones.zones=$zones) order by rating desc $show_only $offset;" #TODO entscheiden ob rating bei mirror sinnvoll
			fi

			sqlite3 $database "select distinct category.name from links, category, category_link where links.id=$id and category_link.item_id=links.id and category_link.category_id=category.id and category.zone in (select zone from zones where zones.zones=$zones) order by category.name;" | xargs echo "Kategorien: "
			echo ""
			echo "----------------------------------------------------"
			echo ""

			if [[ $USE_HISTORY = y ]] ; then
				sqlite3 $database "insert into history (item_id,item_type_id,search_term,categories,ex_categories,zones,timestamp,command,parameters) values ($id,2,'$search_pattern',`echo $categories | sed "s/','/,/g"`,`echo $ex_category | sed "s/','/,/g"`,$zones,(select datetime()),'$SCRIPTNAME','$parameters');"
			fi

		done < $ramdisk/temp_links

	fi
done


###############################
# Infos
###############################

item_types=( 0 1 3 5 7 )
for i in ${item_types[@]}
do
	if [ $i == $item_type_to_search ] ; then

		if [[ $ex_category != "''" ]] ; then
			ex_category_clause="and infos.id not in (select distinct infos.id from infos, category, category_info where category_info.category_id=category.id and category_info.item_id=infos.id and (category.name in ($ex_category) or category.id in (select distinct category_id from category_alias where name in ($ex_category))) and category.zone in (select zone from zones where zones.zones=$zones)) "
		fi


		categories_clause=""
		if [[ $categories != "''" ]] ; then

			for ((j=1; j <= $#; j++)) ; do 
				if [ $j -gt 1 ] ; then	
					categories_clause=" $categories_clause UNION ALL"
				fi
				#echo "j: $j"
				categories_clause="$categories_clause select v_infos.id, v_infos.name, v_infos.text, v_infos.rating, v_infos.zone, DateTime(v_infos.date) as date, DateTime(v_infos.expiration) as expiration, DateTime(v_infos.dateAdded) as dateAdded from v_infos where v_infos.id in 
				(
				select item_id from category_info, category where category_info.category_id=category.id AND category.id in
					(
					${category_layers[$j]}
					) 
					)"
				#echo "categories_clause: $categories_clause"
				done
				categories_clause="($categories_clause) as infos"
			else
				categories_clause="infos"

			fi

# Infos geordnet nach Kategorie_Treffer und rating und Datum ausgeben
# 2013-05-16 msoon: select mit UNION ALL und wieder eingeführtem category_match
dbquery="select infos.name, infos.id, count(*) as category_match, infos.rating, DateTime(infos.date), DateTime(infos.expiration), infos.zone from $categories_clause where 1=1 $info_search $ex_category_clause $search_date $WHERE_PART and infos.zone in (select zone from zones where zones.zones=$zones)
		group by infos.id having category_match>=$# $min_catagorys order by $sort_order $show_only $offset"
		#2012-11-17 count hits everytime like other unix commands do :-)

		hits=`sqlite3 $database "select count(*) from ($dbquery) ;"`

		if [[ $count_hits == 1 ]] ; then
			echo $hits
			exit $EXIT_SUCCESS
		fi

		if [ $hits -gt $hits_before_asking ] ; then

			read -s -n 1 -p "There are $hits infos to show: proceed (Y/n)? " choice
			echo ""

			case "$choice" in
				n|N)	exit $EXIT_SUCCESS	;;
				Y|y|"")	true	;;
			esac
		fi

		if [[ $VERBOSE = y ]] ; then
		  echo hits_before_asking: $hits_before_asking
			echo "INFO - SELECT"
			date +%H:%M:%S:%N
			echo "$dbquery ;"
		fi

		# 2013-03-13 msoon: select ohne category_match  (absolete)

		sqlite3 $database "$dbquery ;" > $ramdisk/temp_infos

		if [[ $VERBOSE = y ]] ; then
			date +%H:%M:%S:%N
		fi

		mkdir $ramdisk/infos 2> /dev/null
		if [[ $KEEP_RESULTS = n ]] ; then
			rm -r $ramdisk/infos/* 2> /dev/null
		fi
		# if [[ $use_clipboard = 1 ]] ; then
		#echo "`head -n1 /mnt/ramdisk/temp_infos`" | xclip -selection clipboard
		##first_hit=`head -n1 /mnt/ramdisk/temp_infos`
		#fi

		# Infos temporär als Dateien anlegen
		while read line
		do
			id=`echo "$line" | cut -f2 -d'|'`
			infoname=`echo "$line" | cut -f1,2 -d'|' | sed "s/|/_/g"`
			rating=`echo "$line" | cut -f4 -d'|'`
			date=`echo "$line" | cut -f5 -d'|' | sed "s/ 00:00:00//g"` #not necassary to show
			expiration=`echo "$line" | cut -f6 -d'|' | sed "s/ 23:59:59//g"` #not necassary to show
			cmatch=`echo "$line" | cut -f3 -d'|'`
			zone=`echo "$line" | cut -f7 -d'|'`

			if [[ $VERBOSE = y ]] ; then
			echo "line=$line"
			echo "id=$id"
			echo "infoname=$infoname"
			fi

			echo ""
			echo "*************************************************" 
			echo -e " \E[32m$infoname  [ Date: \"$date\" \"$expiration\" ] `if [[ $min_catagorys > 0 ]] ; then echo cm:$cmatch; fi`[z:$zone] (rating:$rating)"; tput sgr0  #Infoname is shown green
			if [[ $ADDITIONAL_DB = y ]] ; then
				echo -e "\E[90m [ `basename $database`(RO) ]"; tput sgr0
			else
				echo "use: vinfo \"$ramdisk/infos/$infoname\""
			fi
			sqlite3 $database "select distinct category.name from infos, category, category_info where infos.id=$id and category_info.item_id=infos.id and category_info.category_id=category.id and category.zone in (select zone from zones where zones.zones=$zones) order by category.name;" | xargs echo "Kategorien: "
			echo "*************************************************"
			echo ""
			if [[ $Q_MODE = n ]] ; then
	    if [[ $EXCERPT = n ]] ; then
				sqlite3 $database "select text from infos where infos.id=$id;" | tee $ramdisk/infos/"$infoname"
			else
				sqlite3 $database "select text from infos where infos.id=$id;" | tee $ramdisk/infos/"$infoname" | head -n $EXCERPT_LINES
			fi
				if [[ $SHOW_REFS = a ]] ; then
					echo ""
					echo -e "\E[94m`sqlite3 $database \"select source from links, item_ref where ((item1_id=$id and item1_type_id=1 and item2_type_id=2 and item2_id=links.id) OR (item2_id=$id and item2_type_id=1 and item1_type_id=2 and item1_id=links.id)) AND zone in (select zone from zones where zones.zones=$zones);\"`"; tput sgr0  #url wird blau ausgegeben
				#connected infos
			#	echo ""
				echo "`sqlite3 $database \"select name from infos, item_ref where item1_id=$id and item1_type_id=1 and item2_type_id=1 and item2_id=infos.id AND zone in (select zone from zones where zones.zones=$zones);\"`"  #TODO auslagern
				elif [[ $SHOW_REFS = y ]] ; then
					# 2014-09-04 msoon: one category layer will used here
					# maybe sqlite3 -list to show infos.text below
			#		echo ""
					echo "`sqlite3 $database \"select name from infos, item_ref where item1_id=$id and item1_type_id=1 and item2_type_id=1 and item2_id=infos.id and item2_id in (select item_id from category_info where category_id in (select category_id from category_info where item_id=$id ) OR category_id in (select id from category where parent in (select category_id from category_info where item_id=$id) ) ) AND zone in (select zone from zones where zones.zones=$zones);\"`"


				fi
			fi	
			
			if [[ $USE_HISTORY = y ]] ; then
				sqlite3 $database "insert into history (item_id,item_type_id,search_term,categories,ex_categories,zones,timestamp,command,parameters) values ($id,1,'$search_pattern',`echo $categories | sed "s/','/,/g"`,`echo $ex_category | sed "s/','/,/g"`,$zones,(select datetime()),'$SCRIPTNAME','$parameters');"
			fi

	# ersten Treffer in Zwischenablage kopieren
	#if [ $line == $first_hit ] ; then
	#cat $infoname | xclip ...
	#fi

done < $ramdisk/temp_infos

fi
done

if [[ $use_email == 1 ]] ; then
	echo "---------------------------------------"
	echo -e "\E[93m Results in e-mails and specific files: "; tput sgr0
	echo "---------------------------------------"
	echo ""
	if [[ $VERBOSE = y ]] ; then
		echo "cat $email_and_files | grep $grep_only -i -C3" "$search_pattern" 
	fi
	cat $email_and_files | grep $grep_only -i -C3 "$search_pattern"  # grep without cat and context has the problem that filename is in each line
fi

#TODO parameters should be in config file
if [[ $use_IMDB == 1 ]] ; then
	echo -e "\E[93m The IMDB: "; tput sgr0
	# Requires imdbpy python-lxml
	#get_first_movie.py "\"$search_pattern\"" # | grep 'Rating:'
	# Requires imdbpy python-lxml

	#alternativ
	
	CURL_PATTERN=`echo "$search_pattern" | sed 's/ /+/g'` #also possible to replace space with + for curl
	IMDB_SEARCH=`curl -sS "http://www.imdb.com/find?q=$CURL_PATTERN" | grep -o -m1 "/title/tt.\{3,25\}=fn_al_tt_1" | head -n1`
	
	if [[ $VERBOSE = y ]] ; then
		echo search_pattern: http://www.imdb.com/find?q=$search_pattern 
		echo IMDB_SEARCH http://www.imdb.com#$IMDB_SEARCH
	fi
	curl -s http://www.imdb.com$IMDB_SEARCH > $ramdisk/IMDB_MOVIE #TODO evtl auslagern
	grep -o '<title>.\{4,50\} - IMDb</title>' $ramdisk/IMDB_MOVIE | sed 's/<title>/Title: /g' | sed 's|</title>||g'
	grep "<meta name=\"description\"" $ramdisk/IMDB_MOVIE | sed 's/<meta name="description" content="//g' | sed 's|" />||g'
	grep -o '"ratingValue">.\{3\}' $ramdisk/IMDB_MOVIE | sed 's/"ratingValue">/Rating: /g'

fi

if [[ $use_google == 1 ]] ; then
	surfraw google $search_pattern
	#später evtl möglich: python-gdata googlecl 
fi

if [[ $open_filemanager == 1 ]] ; then
	dolphin --geometry=1024x756 $ramdisk/files &
fi

echo ""

#echo ADDITIONAL_DB: $ADDITIONAL_DB
if [[ $use_add_db = y ]] ; then
# if allready in additional DB exit else search other dbs
	if [[ $ADDITIONAL_DB = y ]] ; then
		exit $EXIT_SUCCESS
	else
		#if [ -f $add_db ] ; then # should work...
		while read line
		do
			if [[ $VERBOSE = y ]] ; then
				echo "Results from $line:"
			fi

			msearch -z $infosystem/add_dbs/$line -k $ALL_ARGS 2> /dev/null
#			count=`msearch -z $infosystem/add_dbs/$line -kc $ALL_ARGS 2> /dev/null`
#		if [[ $count == 0 ]] ; then
#			echo -e "\E[33m there are no results from $line (maybe problem with quotes) try to search manually again: "; tput sgr0
#			echo "  msearch -z $infosystem/add_dbs/$line -k $ALL_ARGS_FIX"
#		fi
		done < $infosystem/cache/add_db_names 
		##fi
	fi
fi

exit $EXIT_SUCCESS
