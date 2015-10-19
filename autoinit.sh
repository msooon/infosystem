#!/bin/bash
# Skript: autoinit.sh

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10


source ${0%/*}/config

grep -o 'zones=.' ${0%/*}/config
#head ${0%/*}/config
echo ""

#sqlite3 $database "select id,name,zone,dateAdded,expiration from infos where date(lastModified)>\"`date -d \"5 days\" +%Y-%m-%d`\"\";"
#diff -q /media/daten/bin/infosystem /mnt/ftp/infosystem/infosystem

#ls -ahl $database /mnt/ftp/infosystem/infosystem

if [ -e leave_mobile_mode.sql ] ; then 
	sqlite3 $database < leave_mobile_mode.sql 2> /dev/null
fi

cp $database $backup/infosystem_`date +%d`.db

today=`date +%d`
if [[ $today = 01 ]] ; then
	./set_zone.sh 7
  date +%Y-%m-%d >> $cached_files/stats
	echo "Infos gesamt" >> $cached_files/stats
	msearch -kpic >> $cached_files/stats
	echo "Links gesamt" >> $cached_files/stats
	msearch -kplc >> $cached_files/stats
	echo "Infos want-todo" >> $cached_files/stats
	msearch -kpic want-todo >>  $cached_files/stats
	echo "Links want-todo" >> $cached_files/stats
	msearch -kplc want-todo >> $cached_files/stats
	echo "" >> $cached_files/stats
	./set_zone.sh $zones
fi

read -n 1 -p "view/edit config before? (Y/n) " choice
if [[ $choice == "n" ]] ; then
	echo ""
	echo "existing config will be used"
else
	$EDITOR ${0%/*}/config 
	source ${0%/*}/config
fi


msearch_opt_args="-pkr40"  #example "-v"
add_category_dirs
echo msearch_opt_args=$msearch_opt_args
echo "running cronjobs..."
run_needed=`sqlite3 $database "select Date('now')>Date(lastModified,'+7 day') from cronjobs where name='weekly'; "`
if [[ $run_needed = 1 ]] ; then
	infocron_weekly
	sqlite3 $database "update cronjobs set lastModified=Date('now') where name='weekly';"
fi
run_needed=`sqlite3 $database "select Date('now')>Date(lastModified) from cronjobs where name='daily';"`
if [[ $run_needed = 1 ]] ; then
  infocron_daily
	sqlite3 $database "update cronjobs set lastModified=Date('now') where name='daily';"
fi
echo ""
echo "searching for movies to check..."
  #2014-08-25 msoon Bei Filmen wird kurzer Text davor gesucht. Dauert deutlich länger aber man kann erkennen ob es sich um den Film handelt oder er nur erwähnt wird
  msearch -pi check television movie >> /dev/null
	cat $ramdisk/infos/* | sed '/^ *$/d' | sed 's/^/.../g' > $ramdisk/movies_tocheck
	msearch -pi check television human >> /dev/null
	cat $ramdisk/infos/* | sed '/^ *$/d' >> $ramdisk/movies_tocheck
echo ""
echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions same Day other Year : "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
#msearch $msearch_opt_args -i l -d" like '`date +%%-%m-%d\'\ and\ Date\(DateAdded\)!=\'%Y-%m-%d`'"
#msearch $msearch_opt_args -i -l -d" like '`date +%%-%m-%d`' and Date(date)!='`date +%Y-%m-%d`'"
msearch $msearch_opt_args -i -l -d" like '`date +%%-%m-%d`'" -w "Date(date)!='`date +%Y-%m-%d`' and Date(dateAdded)!='`date +%Y-%m-%d`'"

echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions same day of the week but other Year: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
#msearch $msearch_opt_args -i -l -d" like '`date -d "8 days" +%%-%m-%d`' and Date(date)!='`date -d "8 days" +%Y-%m-%d`'"
msearch $msearch_opt_args -i -l -d" like '`date -d "8 days" +%%-%m-%d`'" -w "Date(date)!='`date -d "8 days" +%Y-%m-%d`' and Date(dateAdded)!='`date -d "8 days" +%Y-%m-%d`'"


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions six month before: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i -l -d"='`date -d "6 month ago" +%Y-%m-%d`'" 


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions one Month before: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i -l -d"='`date -d "last Month" +%Y-%m-%d`'" -x "done','monthly"


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions Last `date -R | cut -f1 -d','`: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i -l -d"='`date -d "last \`date -R | cut -f1 -d','\`" +%Y-%m-%d`'" -x "done','monthly','beweekly','weekly"


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions 3 Days before: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i -l -d"='`date -d "3 days ago" +%Y-%m-%d`'" -x "done','monthly','biweekly','weekly"


#echo "---------------------------------------------------------------------------"
#echo ""
#echo -e "\E[36m Additions 2 days before: "; tput sgr0
#echo "---------------------------------------------------------------------------"
#echo ""
#msearch $msearch_opt_args -i -l -d"='`date -d "2 days ago" +%Y-%m-%d`'" -x "done','monthly','biweekly','weekly"


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions Yesterday: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i -l -d"='`date -d "Yesterday" +%Y-%m-%d`'" -x "done','monthly','biweekly','weekly"


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[93m Einträge für heute: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
#msearch $msearch_opt_args -i  -d"='`date +%Y-%m-%d`'" -x "done','done1w','done2w','done1m"
#TODAY=`date +%Y-%m-%d`
#msearch $msearch_opt_args -i  -d"='`date +%Y-%m-%d`' or (Date(DateAdded)<='`date +%Y-%m-%d`' and Date(expiration)>='`date +%Y-%m-%d`')"
#die doppelte Abfrage mit DateAdded wird benötigt da Treffer mit expiration is null sonst rausfallen
#2013-02-06 msoon: durch 2 Abfragen ersetzt da wegen 'OR' ansonsten restliche Bedingungen wie zone ignoriert werden
msearch $msearch_opt_args -i  -d"='`date +%Y-%m-%d`'" -x done  #-w "Date(expiration) is null"
#msearch $msearch_opt_args -i -d"<='`date +%Y-%m-%d`'" -w "Date(expiration)>='`date +%Y-%m-%d`'" -x "weekly','biweekly','monthly"
msearch $msearch_opt_args -i  -w "Date(date)<='`date +%Y-%m-%d`' and Date(expiration)>='`date +%Y-%m-%d`'" -x "done','weekly','biweekly','monthly"

echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[93m Termine morgen: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i  -d"='`date -d "1 day" +%Y-%m-%d`'"


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[93m Termine in 2 Tagen: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i  -d"='`date -d "2 days" +%Y-%m-%d`'"


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[93m weitere Termine: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i  -o2 -d">'`date -d "2 days" +%Y-%m-%d`'" -x "weekly','biweekly','monthly"
echo ""
echo "For the full list use: msearch $msearch_opt_args -i  -d\">'`date -d \"2 days\" +%Y-%m-%d`'\""
echo ""

echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[35m TODO's: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args todo
echo ""

echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[35m LastModified Infos: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
sqlite3 $database -header "select infos.id,LastModified, infos.name
	--, substr(text,1,70) 
	from infos
	where 1=1
	and infos.zone in (select zone from zones where zones.zones=$zones)
	ORDER BY LastModified desc LIMIT 10;"

echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[35m want-todo's: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
POSITION=$[ ( $RANDOM % `msearch $msearch_opt_args -cl want-todo` )  ]
msearch $msearch_opt_args -l -o2 -t$POSITION want-todo
POSITION=$[ ( $RANDOM % `msearch $msearch_opt_args -ci want-todo` )  ]
msearch $msearch_opt_args -i -o2 -t$POSITION want-todo
echo ""

#2014-12-21 autoinit_own.sh ausgelagert

./autoinit_own.sh

echo ""

#TIMESTAMP=`date +%H%M`
TIMESTAMP=`date +%H`
if [ -e ~/.tvbrowser ] ; then

	echo -e "\E[93m interesting movies in TV: "; tput sgr0
	if (( $TIMESTAMP > 16 )) ; then
		grep --binary-files=text -of $ramdisk/movies_tocheck ~/.tvbrowser/tvdata/*`date -d "1 day" +%Y%m%d`* | sort -u
	else
		grep --binary-files=text -of $ramdisk/movies_tocheck ~/.tvbrowser/tvdata/*{`date +%Y%m%d`,`date -d "1 day" +%Y%m%d`}* | sort -u
	fi
fi

echo ""

#echo -e "\E[93m Termine in einer Woche: "; tput sgr0
#echo "---------------------------------------------------------------------------"
#echo ""
#msearch -d"='`date -d "7 days" +%Y-%m-%d`'"
#echo "---------------------------------------------------------------------------"
#echo ""

#echo -e "\E[93m Termine in einem Monat: "; tput sgr0
#echo "---------------------------------------------------------------------------"
#echo ""
#msearch -d"='`date -d "next Month" +%Y-%m-%d`'"
#echo "---------------------------------------------------------------------------"
#echo ""

#Häufigkeit von verwendeten Kategorien - nützlich für Interessensuche in anderen Datenbanken
#sqlite3 -header $database "select name, count(*) as anzahl from category,category_item where category.id=category_item.category_id and category.zone in (select zone from zones where zones.zones=$zones) group by category_id having anzahl>50 order by anzahl desc;"

