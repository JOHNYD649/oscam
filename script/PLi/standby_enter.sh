#!/bin/sh

# if directory does not exist, must be created the new one /usr/script/
# bash-script files must be located at this place: /usr/script/*.sh
# new script files in your Enigma2 must to have a execution rights: $ chmod 755 /usr/script/*.sh

# https://github.com/OpenPLi/enigma2/blob/develop/lib/python/Screens/Standby.py
# https://www.opena.tv/english-section/32512-solution-standby-mode-lg-tv-hdmi-cec-simplink.html

# shell command to Turning Off the LG-TV through RS232 interface:

echo "ka 01 00" > /dev/ttyS0