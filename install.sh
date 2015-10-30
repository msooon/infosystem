#!/bin/bash

source ${0%/*}/config  #for definition of $base_path
#Notice: if you change $bin_path or $infosystem in config you also have to change static path in msearch.sh or use following symlink
#ln -s $base_path /media/daten
bin_path=$infosystem
user=1000 #in most cases this is right - but you can also add your username here
mkdir $bin_path  2> /dev/null 
mkdir -p $infosystem/cache  2> /dev/null  #TODO check before
mkdir -p $infosystem/add_dbs  2> /dev/null
mkdir -p $backup 2> /dev/null
chown -R $user:$user $infosystem

cd /usr/local/bin || exit

# choose a symlink to work easier with categories
#ln -s /mnt/ramdisk/category /category
#ln -s /tmp/category /category
 ln -s $bin_path/config config

 ln -s $bin_path/add_category_alias.sh add_category_alias
 ln -s $bin_path/add_category_dirs.sh add_category_dirs
 ln -s $bin_path/add_category.sh add_category
 ln -s $bin_path/add_category_alias.sql add_category_alias.sql
 ln -s $bin_path/add_category_dirs.sql add_category_dirs.sql
 ln -s $bin_path/add_file.sh add_file
 ln -s $bin_path/add_files.sh add_files
 ln -s $bin_path/add_info.sh add_info
 ln -s $bin_path/add_lightning_entries.sh add_lightning_entries
 ln -s $bin_path/add_link.sh add_link
 ln -s $bin_path/add_moz_bookmarks.sh add_moz_bookmarks
 ln -s $bin_path/add_moz_downloads.sh add_moz_downloads
 ln -s $bin_path/autoinit.sh autoinit
 ln -s $bin_path/autoinit_gestern.sh autoinit_gestern
 ln -s $bin_path/backup_file.sh backup_file
 ln -s $bin_path/create_info_file.sh create_info_file
 ln -s $bin_path/customize_info.sh customize_info
 ln -s $bin_path/infocron_daily.sh infocron_daily
 ln -s $bin_path/infocron_weekly.sh infocron_weekly
 ln -s $bin_path/loop.sh loop
 ln -s $bin_path/msearch.sh msearch
 ln -s $bin_path/rm_category_alias.sh rm_category_alias
 ln -s $bin_path/rm_category.sh rm_category
 ln -s $bin_path/rm_file.sh rm_file
 ln -s $bin_path/rm_info.sh rm_info
 ln -s $bin_path/rm_link.sh rm_link
 ln -s $bin_path/rm_tag_file.sh rm_tag_file
 ln -s $bin_path/rm_tag_info.sh rm_tag_info
 ln -s $bin_path/rm_tag_link.sh rm_tag_link
 ln -s $bin_path/set_zone.sh set_zone
 ln -s $bin_path/show_refs.sh show_refs
 ln -s $bin_path/show_used_documents.sh show_used_documents
 ln -s $bin_path/tag_file.sh tag_file
 ln -s $bin_path/tag_info.sh tag_info
 ln -s $bin_path/tag_link.sh tag_link
 ln -s $bin_path/update_files.sh update_files
 ln -s $bin_path/update_infos.sh update_infos
 ln -s $bin_path/vinfo.sh vinfo
	
