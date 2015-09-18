#!/bin/bash

source ${0%/*}/config

sqlite3 -separator '/' $database "select * from (select distinct a.name,b.name,c.name,d.name from category as a inner join category as b on a.id=b.parent inner join category as c on b.id=c.parent inner join category as d on c.id=d.parent where a.parent=0 and a.zone in (select zone from zones where zones=$zones) and b.zone in (select zone from zones where zones=$zones) and c.zone in (select zone from zones where zones=$zones) and d.zone in (select zone from zones where zones=$zones) union select distinct a.name,b.name,c.name,'' from category as a inner join category as b on a.id=b.parent inner join category as c on b.id=c.parent where a.parent=0 and a.zone in (select zone from zones where zones=$zones) and b.zone in (select zone from zones where zones=$zones) and c.zone in (select zone from zones where zones=$zones) union select distinct a.name,b.name,'','' from category as a inner join category as b on a.id=b.parent where a.parent=0 and a.zone in (select zone from zones where zones=$zones) and b.zone in (select zone from zones where zones=$zones) union select distinct a.name,'','','' from category as a where a.parent=0 and a.zone in (select zone from zones where zones=$zones)) order by 1,2,3,4;"  > $ramdisk/category_dirs

sqlite3 -separator ' ' $database "select category.name, category_alias.name from category, category_alias where category.id=category_alias.category_id and category.zone in (select zone from zones where zones=$zones);" > $ramdisk/category_dir_alias
rm -r $ramdisk/category/* 2> /dev/null
mkdir $ramdisk/category 2> /dev/null
cd $ramdisk/category || exit

if [[ $category_flat_mode != 1 ]] ; then
while read line
do
  mkdir -p ./"$line" 2> /dev/null
done < $ramdisk/category_dirs

while read line
do
  cd `echo $line | awk '{printf "%s ",$1 }' | xargs find -name`/.. >> /dev/null || exit #landet eine Ebene unter der Kategorie
  ln -s $line 2> /dev/null
  cd - >> /dev/null || exit
done < $ramdisk/category_dir_alias

fi

if [[ $category_flat_mode > 0 ]] ; then
cd $ramdisk/category || exit
while read line
do
  touch "`basename $line`" 2> /dev/null
done < $ramdisk/category_dirs

while read line
do
  ln -s $line 2> /dev/null
done < $ramdisk/category_dir_alias

fi

# Systemkategorien in zone=0 anlegen (sollen sonst nicht angezeigt werden)
touch $ramdisk/category/done
#touch $ramdisk/category/done1w
#touch $ramdisk/category/done2w
#touch $ramdisk/category/done1m
#touch $ramdisk/category/done4m
touch $ramdisk/category/use_clipboard

# Entferne tote links
find $ramdisk/category -type l -! -exec test -e {} \; -print | xargs rm #TODO prevent creation of dead links

cd $ramdisk/
ln -s ${0%/*}/config config 2> /dev/null
ln -s ${0%/*}/tag_items_in_folder tag_items_in_folder.sh 2> /dev/null
ln -s ${0%/*}/update_infos update_infos.sh 2> /dev/null
ln -s ${0%/*}/update_files update_files.sh 2> /dev/null

