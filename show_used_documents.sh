#!/bin/bash

# tested with kde4
source ${0%/*}/config

echo ""
echo -e "\E[93m Recent Documents Kde: "; tput sgr0
echo ""
ln -s ~/.kde4/share/apps/RecentDocuments/ $ramdisk/RecentDocuments_Kde 2> /dev/null
cat $ramdisk/RecentDocuments_Kde/*
echo ""
echo -e "\E[93m RecentPrograms Kde: "; tput sgr0
echo ""
grep -A1 RecentlyUsed ~/.kde4/share/config/kickoffrc | tee $ramdisk/RecentPrograms_Kde.txt
echo ""
echo -e "\E[93m further Recent Documents Kde: "; tput sgr0
echo ""
grep -i recent ~/.kde4/share/config/session/* | tee $ramdisk/furtherRecentDocuments_Kdeapps.txt
echo ""
echo -e "\E[90m Recent Programs bash: "; tput sgr0
echo ""
cat ~/.bash_history | tail -n20 | cut -d' ' -f1 |sort -u | tee $ramdisk/Recent_Programs_bash.txt
echo ""
echo -e "\E[90m Most used programs bash: "; tput sgr0
cat ~/.bash_history | cut -d' ' -f1 |sort |uniq -c |sort -nbr |head -n10 | tee $ramdisk/Most_Used_Programs_bash.txt
