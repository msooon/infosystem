#!/bin/bash

#usage
#backup_file [name] [backup] [c for cp] [a=for_alter] #full pathes needed

source ${0%/*}/config

echo `basename "$1"`,`file -F',' -b --mime-type "$1"` | grep -v application/x-directory | sed "s/,/',trim('/g" | sed "s/$/')/g" > /mnt/ramdisk/test

#file_inode=`find $1 -maxdepth 0 -type f -printf '%i\n'`

#cat "$1"
#"'`cat \"$1\"`'"


#um discsource automatisch zu bestimmen
bdisksource=`echo "$1" | awk -F'/' '//{printf "/%s/%s/.diskinfo",$2,$3}' | xargs head -n1`
disksource=`echo "$2" | awk -F'/' '//{printf "/%s/%s/.diskinfo",$2,$3}' | xargs head -n1`

if [ "$3" == "c" ] #if c is set cp the file
#create backup
then
cp "$1" "$2"
fi

inode=`find "$2" -maxdepth 0 -type f -printf '%i\n'`
binode=`find "$1" -maxdepth 0 -type f -printf '%i\n'`

sqlite3 $database "insert into files (name,mediatype,disksource,inode,bdisksource,binode,zone) values ('`cat $ramdisk/test`,'$disksource',$inode,'$bdisksource',$binode,$zones);"

echo "file added"


if [ "$4" == "a" ] #if backup should be used for altering later
then
	echo "backup can be alterd later"
fi
