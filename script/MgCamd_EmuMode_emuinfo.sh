#!/bin/sh
echo "          **Change to EMU mode...**  "
sed -i '/G: / c\G: { 00 }' /usr/keys/mg_cfg
echo "          **-=EMU=- mode ACTIVATED!!! G: { 00 }**  "
#
#
#
#
echo "          **Emu Restart to Run on EMU mode**  "
killall dsemud
sleep 4
/bin/dsemud > /dev/null 2>&1