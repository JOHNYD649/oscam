#!/bin/sh
echo "          **Change to Gbox-mix client mode...**  "
sed -i '/G: / c\G: { 09 }' /usr/keys/mg_cfg
echo "          **Gbox Client- mode ACTIVATED!!!G: { 09 }**  "
#
#
#
#
echo "          **Emu Restart to Run on Gbox Client mode**  "
killall dsemud
sleep 4
/bin/dsemud > /dev/null 2>&1