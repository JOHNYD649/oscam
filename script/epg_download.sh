#!/bin/sh


#### CRON config example - download epg.dat file, every day, at 5:00
#### 00 5 * * *        /bin/sh /usr/script/epg_download.sh


online_file="http://example.com/iptv/epg.dat"           # online server with the "epg.dat" stored file
local_file="/etc/enigma2/epg.dat"
log_file="/tmp/epg_download.log"
tmp_file="/tmp/e"


#if [ "$(wget -q -O - http://127.0.0.1/web/powerstate | grep '</e2instandby>' | cut -f 1)" == "false" ]; then
#    echo `date '+%Y-%m-%d %H:%M:%S'`": Enigma2 is not in Standby. EPG-file downloading script was canceled." >> $log_file
#    exit 0
#fi


if wget --spider ${online_file} 2>/dev/null; then       # check the existence of an online file
    if wget -q -O $tmp_file "$online_file" > /dev/null 2>&1 && [ "$(wc -c < $tmp_file)" != "$(wc -c < $local_file)" ]; then
        mv -f $tmp_file $local_file
        wget -q -O - "http://127.0.0.1/web/loadepg" > /dev/null 2>&1         # reload epg.dat file - using the Enigma2 Open-Webif
        echo `date '+%Y-%m-%d %H:%M:%S'`": $online_file file was downloaded, replaced and reloaded in your Enigma2" >> $log_file
    else
        echo `date '+%Y-%m-%d %H:%M:%S'`": $online_file file was downloaded, but not replaced (it is the same file size as local file in Enigma2)" >> $log_file
    fi
    rm -f $tmp_file
else
    echo `date '+%Y-%m-%d %H:%M:%S'`": $online_file file was not found !" >> $log_file
fi


exit 0
