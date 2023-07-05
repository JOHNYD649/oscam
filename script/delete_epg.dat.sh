#!/bin/sh
#Franc - 2018 (PurE2)

if tty > /dev/null ; then
   RED='-e \e[00;31m'
   GREEN='-e \e[00;32m'
   YELLOW='-e \e[01;33m'
   BLUE='-e \e[00;34m'
   PURPLE='-e \e[01;31m'
   WHITE='-e \e[00;37m'
else
   RED='\c00??0000'
   GREEN='\c0000??00'
   YELLOW='\c00????00'
   BLUE='\c0000????'
   PURPLE='\c00?:55>7'
   WHITE='\c00??????'
fi


echo -n $BLUE
printf "Searching for epg.dat, please wait... \n"
export epgfilename=`find / -name epg.dat`
echo -n $YELLOW
#printf $epgfilename " \n"

if [ -f "$epgfilename" ]; then
    printf "epg.dat found in $GREEN $epgfilename \n"
    sleep 1
    printf "Deleting... \n"
    sleep 1
    printf "Done! \n\n"
    echo -n $BLUE
    printf "Rebooting in 3 seconds, please wait ... \n"
    init 4
    rm -f $epgfilename
    sleep 2
    init 3
else
    echo -n $YELLOW
    printf "Sorry, can't find epg.dat"
fi
exit 0
