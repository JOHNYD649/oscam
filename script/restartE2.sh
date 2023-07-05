#!/bin/sh
#Franc - 2018 (PurE2)

PATH=/sbin:/bin:/usr/sbin:/usr/bin

echo -n "Restarting E2... "
init 4
sleep 1
init 3
