#!/bin/bash

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

#usage
#add_file [name] [Kategorien ...] 

source ${0%/*}/config

inode=`find "$1" -maxdepth 0 -type f -printf '%i\n'`

#um discsource automatisch zu bestimmen
disksource=`echo "$1" | awk -F'/' '//{printf "/%s/%s/.diskinfo",$2,$3}' | xargs head -n1`

mediatype=`file -F',' --mime-type "$1" | grep -v application/x-directory | cut -f2 -d','`
mediatype_trim=`sqlite3 $database "select trim('$mediatype')"`

if [[ $VERBOSE = y ]] ; then
echo "mediatype_trim: $mediatype_trim"
fi
filename=`basename "$1"`

next_id=`sqlite3 $database "select coalesce ( (select id from files where name='' order by id limit 1),(select max(id)+1 from files),1 ); "`

sqlite3 $database "delete from files where id=$next_id; "

sqlite3 $database  "insert into files (id,name,mediatype,disksource,inode,zone) values ('$next_id','$filename','$mediatype_trim','$disksource',$inode,$zones);"

echo "inserted id: $next_id"

categorys=""
num_categorys=0

categorys="${*:2} `echo "$1" | sed 's;/; ;g'`"

if [[ $VERBOSE = y ]] ; then
	echo -e "\E[35mcategorys: $categorys"; tput sgr0
fi

# 20111115 tag_file wird verwendet um Kategorien oberhalb zu löschen
tag_file "$next_id" $categorys

# 20111115 Abfrage entfernt um es besser in andere Skripte einbauen zu können
#read -n 1 -p "Give custom rating and votes? (Y/n) " choice #

echo ""
