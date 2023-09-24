#!/bin/sh

#### The problem with some firmware on IRDETO cards is that after an 1 hour in idle time, "Entitlements" are lost.
#### Then they have to be reloaded through EMMs, which sometimes takes up to 5 - 20 seconds.

#### This script is designed to re-wake the DVB tuner once per hour and wait for 1 minute to receive EMMs.
#### These EMMs are then automatically sent to the decoder card.

#### The script is activated every 10 minutes and does the following:
####
#### The Standby mode is tested first, and then the length of time the Oscam is idle is tested. 
#### If the Enigma is in Standby and the Oscam idle time is longer than 3600 seconds (1 hour), the satellite tuner will turn on and wait for EMM reception for 1 minute.

#### 1) for OpenATV / OpenPLi Enigma please copy the script file into the directory "/usr/script" (create the directory if does not exist)
####    in the case of other Enigma, copy the script where you see fit (!!! but not to the directory "/tmp" !!!)
####
#### 2) assign the execution attributes to the script file:
####        chmod a+x /usr/script/oscam_emm_refresh.sh
####
#### 3) to start the script between 06:00 and 23:00, every 10 minutes, add the following line into the CRON configuration file:
####        */10 6-23 * * *     sh /usr/script/oscam_emm_refresh.sh
####
#### Note:
####    During editing the CRON config file (/etc/cron/crontabs/root), the CRON daemon must be stopped (as prevention),
####    so, use the following command-line (OpenATV Enigma):
####        /etc/init.d/crond {start|stop|restart}  # use the stop argument before edit and when all will done, then use the start argument to start daemon again

#### Version history:
####        04.10.2018 - script proposed by s3n0
####        30.01.2019 - minor repairs

#### For a testing purpose:
####        wget -q -O /tmp/test-oscam-api.xml $WEBIF_OSCAM/oscamapi.html?part=status
####        cat /tmp/test-oscam-api.xml | sed -rn '/name="'$READER_LABEL'"/,/times/p'
####        cat /tmp/test-oscam-api.xml | sed -rn '/name="'$READER_LABEL'"/,/times/ {s/.*idle="([0-9]+)".*/\1/p}'

#### USER CONFIGURATION:
WEBIF_ENIGMA="http://127.0.0.1:80"                  # use "http://LOGIN:PASSWORD@127.0.0.1:PORT"  if you also use a password for Enigma-Webif
WEBIF_OSCAM="http://127.0.0.1:8888"                 # use "http://LOGIN:PASSWORD@127.0.0.1:PORT"  if you also use a password for Oscam-Webif
READER_LABEL="reader_sci0"                          # card-reader name
IDLE_TIME=3600                                      # the time interval [sec.] to retreive a new EMMs (only when Enigma is standby)
EMM_AWAITING="1m"                                   # awaiting to EMM arrival (1m = meaning 1 min. waiting time, 30s = meaning 30 secs, ... etc.)
SRC="1:0:19:3731:C8E:3:EB0000:0:0:0:"               # channel used for receive some EMMs - in this case as a SAT-channel Markiza-HD on the satellite Astra-3B / 23.5E => Service Reference Code = 1:0:19:3731:C8E:3:EB0000:0:0:0:
LOG_FILE="/tmp/oscam_emm_refresh.log"               # use "/dev/null" to disable the .log file
LOG_MAXSIZE=25000                                   # max. file size [Bytes]

#### function to check the Standby (e2/OpenWebif power-state)
is_standby(){
	[ "$(wget -q -O - $WEBIF_ENIGMA/web/powerstate | grep '</e2instandby>' | cut -f 1)" = "true" ]
}

#### reduction the log file size, if neccessary (delete first 20 lines)
if [ -f "$LOG_FILE" ] && [ $(wc -c < "$LOG_FILE") -gt $LOG_MAXSIZE ]; then sed -i -e 1,20d "$LOG_FILE"; fi

#### if Enigma is not in standby, exit the script
if ! is_standby; then echo `date '+%Y-%m-%d %H:%M:%S'`": Enigma2 is not in Standby. Script canceled." >> $LOG_FILE; exit 0; fi

#### in another step will check the card-reader idle time...
#### if the idle time of the specific card $READER_LABEL in Oscam is greater than $IDLE_TIME, then EMM refresh begins (zap to the satellite channel for a short time period), otherwise exiting script
if [ $(wget -q -O - $WEBIF_OSCAM/oscamapi.html?part=status | sed -rn '/name="'$READER_LABEL'"/,/times/ {s/.*idle="([0-9]+)".*/\1/p}') -gt $IDLE_TIME ]
then
	wget -q -O - "$WEBIF_ENIGMA/web/zap?sRef=$SRC" > /dev/null 2>&1
	echo `date '+%Y-%m-%d %H:%M:%S'`": Start channel descrambling - $SRC + waiting for EMM arrival (for $EMM_AWAITING time)." >> $LOG_FILE
	sleep $EMM_AWAITING          # sleep 30s        # sleep 2m
else
	echo `date '+%Y-%m-%d %H:%M:%S'`": The $READER_LABEL reader idle time is not greater than the configured $IDLE_TIME secs. Script canceled." >> $LOG_FILE
	exit 0
fi

#### at the end of script execution we have to recheck the standby mode
#### if a user has accidentally switched on a satellite receiver until the script was waiting for EMMs write
if ! is_standby
then
	echo `date '+%Y-%m-%d %H:%M:%S'`": Enigma2 has been awakened (by user's intervention ? using the remote control ?). Script canceled." >> $LOG_FILE
	exit 0
else
	wget -q -O - "$WEBIF_ENIGMA/web/zap?sRef=-1" > /dev/null 2>&1
	echo `date '+%Y-%m-%d %H:%M:%S'`": Stop channel descrambling." >> $LOG_FILE
	#wget -q -O - "$WEBIF_ENIGMA/web/powerstate?newstate=5" > /dev/null 2>&1
	#echo `date '+%Y-%m-%d %H:%M:%S'`": Set-top-box has been switched to Standby" >> $LOG_FILE
fi


exit 0

