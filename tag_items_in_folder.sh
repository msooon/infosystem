#!/bin/bash

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10


source ${0%/*}/config

# Variablen für Optionsschalter hier mit Default-Werten vorbelegen
VERBOSE=n
OPTFILE=""


#Files

cd "$ramdisk"/files
find * -type f > $ramdisk/files_in_folders

while read line
do
	file=`echo $line | awk -F'/' '//{print $NF}'`
	tag_file "$file" `echo $line | sed "s;/; ;g" | sed "s;$file;;g" `
done < $ramdisk/files_in_folders

#Links
cd "$ramdisk"/links
find * -type f > $ramdisk/links_in_folders

while read line
do
	links=`echo $line | awk -F'/' '//{print $NF}'`
	tag_info "$link" `echo $line | sed "s;/; ;g" | sed "s;$link;;g" `
done < $ramdisk/links_in_folders

#Infos
cd "$ramdisk"/infos
find * -type f > $ramdisk/infos_in_folders

while read line
do
	info=`echo $line | awk -F'/' '//{print $NF}'`
	tag_info "$info" `echo $line | sed "s;/; ;g" | sed "s;$info;;g" `
done < $ramdisk/infos_in_folders

exit $EXIT_SUCCESS
