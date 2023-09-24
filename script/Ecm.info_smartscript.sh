#!/bin/sh
#DESCRIPTION=It shows actual ECM.info 

if [ -e /tmp/ecm.info ]; then
	cat /tmp/ecm.info
else
	echo "No /tmp/ecm.info"
fi

