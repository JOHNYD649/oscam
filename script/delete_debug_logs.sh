#!/bin/sh
#Franc - 2018 (PurE2)

printf "Searching for debug logs, please wait... \n"
export debuglogfilename=`find / -name Enigma2-debug*`
echo "."
echo ".."
rm -f $debuglogfilename
sleep 1
echo "..."
echo "done!"
echo " "
exit 0
