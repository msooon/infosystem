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

sqlite3 $database < leave_mobile_mode.sql 2> /dev/null

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


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions same Day other Year : "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
#msearch $msearch_opt_args -i l -d" like '`date +%%-%m-%d\'\ and\ Date\(DateAdded\)!=\'%Y-%m-%d`'"
#msearch $msearch_opt_args -i -l -d" like '`date +%%-%m-%d`' and Date(date)!='`date +%Y-%m-%d`'"
msearch $msearch_opt_args -i -l -d" like '`date -d "1 day ago" +%%-%m-%d`'" -w "Date(date)!='`date -d "1 day ago" +%Y-%m-%d`' and Date(dateAdded)!='`date -d "1 day ago" +%Y-%m-%d`'"
echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions same day of the week but other Year: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
#msearch $msearch_opt_args -i -l -d" like '`date -d "8 days" +%%-%m-%d`' and Date(date)!='`date -d "8 days" +%Y-%m-%d`'"
msearch $msearch_opt_args -i -l -d" like '`date -d "7 days" +%%-%m-%d`'" -w "Date(date)!='`date -d "7 days" +%Y-%m-%d`' and Date(dateAdded)!='`date -d "7 days" +%Y-%m-%d`'"


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions six month before: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i -l -d"='`date -d "6 month ago 1 day ago" +%Y-%m-%d`'" 


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions one Month before: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i -l -d"='`date -d "last Month 1 day ago" +%Y-%m-%d`'" -x "done','monthly"


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions last week same day "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i -l -d"='`date -d "8 days ago" +%Y-%m-%d`'" -x "done','monthly','beweekly','weekly"


echo "---------------------------------------------------------------------------"
echo ""
echo -e "\E[36m Additions 3 Days before: "; tput sgr0
echo "---------------------------------------------------------------------------"
echo ""
msearch $msearch_opt_args -i -l -d"='`date -d "4 days ago" +%Y-%m-%d`'" -x "done','monthly','biweekly','weekly"


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
msearch $msearch_opt_args -i -l -d"='`date -d "2 days ago" +%Y-%m-%d`'" -x "done','monthly','biweekly','weekly"


