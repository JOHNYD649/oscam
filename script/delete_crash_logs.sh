#!/bin/sh
#Franc - 2018 (PurE2)

printf "Searching for crash logs, please wait... \n"
export crashfilename=`find / -name enigma2_crash*`
echo "."
echo ".."
rm -f $crashfilename
sleep 1
echo "..."
echo "done!"
echo " "
exit 0
