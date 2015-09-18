#!/bin/bash

#usage
#loop $INK "$COMMAND $Parameter INK $Parameter POSITION"
#Bsp / Example
#loop 10 "msearch -oINK -tPOSITION song" # loop shows 10 hits each walk
#TODO it should work with scripts using user input

source ${0%/*}/config
echo ""
echo ""

INK=$1
COMMAND=$2
POSITION=0

while true 
do

echo $COMMAND | sed "s/INK/$INK/g" | sed "s/POSITION/$POSITION/g" | xargs bash  

read -n 1 -p "Proceed? (Y/n)" choice #

if [[ $choice = n ]] ; then
   echo ""
   exit $EXIT_SUCCESS
else
echo ""
fi
POSITION=`expr $POSITION + $INK`

done

