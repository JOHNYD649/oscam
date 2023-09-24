#!/bin/sh 
port=`grep "<tcp_port>" /var/tuxbox/config/newcs.xml | sed "s/^.*<.*>\(.*\).*<.*>.*$/\1/"`
temp=/tmp/ncs.info

 
(  echo '01 02 03 04 05 06 07 08 09 10 11 12 13 14' 
   sleep 2 
   echo 'sub -1' 
   echo 'exit' 
)| nc localhost $port > $temp
sed -e "1,14d;33,42d" $temp > /tmp/ncs.txt
cat /tmp/ncs.txt
rm -rf /tmp/ncs.info
rm -rf /tmp/ncs.txt