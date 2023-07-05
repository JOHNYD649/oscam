#!/bin/sh
echo "          **Change to Newcamd client mode...**  "
sed -i '/G: / c\G: { 01 }' /usr/keys/mg_cfg
echo "           **NEWCAMD Client- mode ACTIVATED!!!G: { 01 }**  "
#
#
#
#
echo "          **Emu Restart to Run on NewCamd Client mode**  "
killall dsemud
sleep 4
/bin/dsemud > /dev/null 2>&1