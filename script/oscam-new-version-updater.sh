#!/bin/bash



#######################################
# Oscam new version updater
#######################################
#
# 2019/10/21 - shell script written by s3n0
#
# This script checks if there is a newer version of Oscam on the internet and if so,
# then downloads and overwrites the found Oscam binary file on the local disk.
#
# This script is designed to avoid having to add another 'feed/source' to your Enigma.
#
# Unfortunately the '7zip' archiver is required since the 'ar' tool is problematic when splitting files (inside the IPK package).
#
# To run my script on your set-top box, directly from the github, use the following command:
#       wget -qO- --no-check-certificate "https://github.com/s3n0/e2scripts/raw/master/oscam-new-version-updater.sh" | bash
#
#######################################
#
# This script uses "updates.mynonpublic.com" as an update source and also uses the Python source code,
# from the script by @SpaceRat:
#       http://updates.mynonpublic.com/oea/feed
#
# The original 'feed' script was developed by @SpaceRat for the purpose of installing softcam-feed into Enigma/OpenATV,
# but it also works in other Enigmas. Use the following command to install the feed:
#       wget -O - -q http://updates.mynonpublic.com/oea/feed | bash
#
#######################################






## OSCAM_LOCAL_PATH="/usr/bin/oscam"
## [ -f $OSCAM_LOCAL_PATH ] || { echo "ERROR ! User-configured binary file $OSCAM_LOCAL_PATH not found !"; exit 1; }

OSCAM_LOCAL_PATH=$(find /usr/bin -iname 'oscam*' | head -n 1)
[ -z "$OSCAM_LOCAL_PATH" ] && { OSCAM_LOCAL_PATH="/usr/bin/oscam"; echo "Oscam binary file was not found in folder '/usr/bin'. The default path and filename $OSCAM_LOCAL_PATH will be used to download and to add a new Oscam binary file."; } || echo "Recognized binary file: $OSCAM_LOCAL_PATH"

## OSCAM_LOCAL_PATH=$(ps --no-headers -f -C oscam | sed 's@.*\s\([\-\_\/a-zA-Z]*\)\s.*@\1@' | head -n 1)
## [ -z "$OSCAM_LOCAL_PATH" ] && { OSCAM_LOCAL_PATH="/usr/bin/oscam"; echo "No Oscam process name found. The default file name $OSCAM_LOCAL_PATH will be used to download and add a new Oscam."; } || echo "Oscam process $OSCAM_LOCAL_PATH found."






REQUESTED_BUILD="oscam-trunk"
#REQUESTED_BUILD="oscam-emu"

# - some examples of Oscam builds included on the feed server, there is possible to change one of them:
#
#       oscam-trunk             !!!! does not work ????
#       oscam-trunk-ipv4only    !!!! does not work ????
#
#       oscam-stable
#       oscam-stable-ipv4only
#
#       oscam-emu
#       oscam-emu-ipv4only





IRDETO_ENTITLEMENTS="no"       # please choice your option "no" or "yes", for IRDETO satellite cards, due to necessary "entitlements" (receipt of first EMMs) - the waiting time in the script is set to 30 seconds
IRDETO_CHANNEL="1:0:19:3731:C8E:3:EB0000:0:0:0:"





# A temporary directory
TMP_DIR="/tmp/oscam_binary_update"



HR_LINE="----------------------------------"





#######################################
#######################################
#######################################



#### Auto-configuring the Enigma version and the chipset / CPU architecture (with the help of Python):

# OEVER="4.3"                           # this value is determined automatically using the Python script below - a note: OEVER here means the OE-Alliance version ! not the OE-core version (by Dreambox) !
# ARCH="mips32el"                       # this value is determined automatically using the Python script below
# BASE_FEED="http://updates.mynonpublic.com/oea"       # feed server with all Oscam packages (for OpenATV of course)
# Wget example:      wget -O /tmp/Packages.gz "$BASE_FEED/$OEVER/$ARCH/Packages.gz"
# Specific URL example:     "http://updates.mynonpublic.com/oea/4.3/{mips32el,cortexa15hf-neon-vfpv4,cortexa9hf-neon,armv7ahf-neon,aarch64,sh4}/Packages.gz"

[ -e /usr/bin/python3 ] && PY="python3" || PY="python"

BASE_FEED="http://updates.mynonpublic.com/oea"




get_oever() {
    OEVER=$($PY - <<END
import sys
sys.path.append("/usr/lib/enigma2/python")
try:
    from boxbranding import getOEVersion
    print(getOEVersion().replace("OE-Alliance ", ""))
except:
    print("unknown")
END
    )
    if [ "x$OEVER" == "xunknown" ]; then
        if [[ -x "/usr/bin/openssl" ]]; then
            SSLVER=$(openssl version | awk '{ print $2 }')
            case "$SSLVER" in
                1.0.2a|1.0.2b|1.0.2c|1.0.2d|1.0.2e|1.0.2f)
                    OEVER="unknown"
                    ;;
                1.0.2g|1.0.2h|1.0.2i)
                    OEVER="3.4"
                    ;;
                1.0.2j)
                    OEVER="4.0"
                    ;;
                1.0.2k|1.0.2l)
                    OEVER="4.1"
                    ;;
                1.0.2m|1.0.2n|1.0.2o|1.0.2p)
                    OEVER="4.2"
                    ;;
                1.0.2q|1.0.2r|1.0.2s)
                    OEVER="4.3"
                    ;;
                *)
                    OEVER="unknown"
                    ;;
            esac
        fi
    fi
}


get_arch() {
    ARCH=$($PY - <<END
import sys
sys.path.append("/usr/lib/enigma2/python")
try:
    from boxbranding import getImageArch
    print(getImageArch())
except:
    print("unknown")
END
    )
    if [ "x$ARCH" == "xunknown" ]; then
        case "$OEVER" in
            3.4|4.0)
                ARCH="armv7a-neon"
                ;;
            4.1)
                ARCH="armv7athf-neon"
                ;;
            *)
                ARCH="armv7a"
                ;;
        esac
        echo $(uname -m) | grep -q "aarch64" && ARCH="aarch64"
        echo $(uname -m) | grep -q "mips" && ARCH="mips32el"
        echo $(uname -m) | grep -q "sh4" && ARCH="sh4"
        if echo $(uname -m) | grep -q "armv7l"; then
            echo $(cat /proc/cpuinfo | grep "CPU part" | uniq) | grep -q "0xc09" && ARCH="cortexa9hf-neon"
            if echo $(cat /proc/cpuinfo | grep "CPU part" | uniq) | grep -q "0x00f"; then
                case "$OEVER" in
                    3.4)
                        ARCH="armv7ahf-neon"
                        ;;
                    *)
                        ARCH="cortexa15hf-neon-vfpv4"
                        ;;
                esac
            fi
        fi
    fi
}


check_compat() {
    case "$OEVER" in
        unknown)
            echo "Broken boxbranding ..."
            exit 1
            ;;
        3.4)
            ;;
        3.*)
            echo "Your image is EOL ..."
            exit 1
            ;;
        2.*)
            echo "Your image is EOL ..."
            exit 1
            ;;
        1.*)
            echo "Your image is EOL ..."
            exit 1
            ;;
        0.*)
            echo "Your image is EOL ..."
            exit 1
            ;;
    esac
    if [ "x$ARCH" == "xunknown" ]; then
        echo "Broken boxbranding ..."
        exit 1
    fi
}


get_oever
get_arch
check_compat


#######################################
#######################################
#######################################


#### Unfortunately, OpenPLi-7.2 uses older versions of some libraries (/lib/libc-2.25.so), so... I have to use older OEVER="4.1" core to work the Oscam under OpenPLi-7.2:
[ -f /etc/opkg/all-feed.conf ] && cat /etc/opkg/all-feed.conf | grep -q "openpli-7" && OEVER="4.1"

#### Unfortunately, OpenATV-6.4 has a problem with the OE-Alliance core 4.4, because the feed http://updates.mynonpublic.com/oea/4.4/mips32el/Packages.gz is dead, so I'm using 4.3 core for downloading Oscam
#[ -f /etc/opkg/all-feed.conf ] && cat /etc/opkg/all-feed.conf | grep -q "openatv-all[[:space:]]http://feeds2.mynonpublic.com/6.4/" && OEVER="4.3"

#### Checking if the 7-zip archiver is installed on system
if [ -f /usr/bin/7z ]; then
    BIN7Z=/usr/bin/7z
else
    echo "ERROR ! The '7z' archiver was not found !"
    if [ -f /usr/bin/7za ]; then
        echo "--- Although the standalone '7za' archiver has been found, it does not support the 'ar' method of splitting .ipk / .deb files!"
        echo "--- Unfortunately, the outer layer of the '.ipk' file must be split with the 'ar' method."
    fi
    echo "Please install the '7z' archiver from the Enigma feed, for example, using the following commands:"
    echo "    opkg update"
    echo "    opkg install p7zip-full"
    echo "Note:"
    echo "Do not use '7za' archiver ! It does not support the 'ar' method of splitting .ipk / .deb files!"
    exit 1
fi

#### Download and unpack the list of all available packages + Find out the package name according to the required Oscam edition
echo "$HR_LINE"
echo -n "Downloading and unpacking the list of softcam installation packages... "
IPK_FILENAME=$(wget -q -O - "$BASE_FEED/$OEVER/$ARCH/Packages.gz" | gunzip -c | grep "Filename:" | grep "$REQUESTED_BUILD"_1.20 | cut -d " " -f 2)
[ -z "$IPK_FILENAME" ] && { echo " failed!"; exit 1; } || echo " done."

#### Create the temporary subdirectory and go in
rm -fr $TMP_DIR ; mkdir -p $TMP_DIR ; cd $TMP_DIR

#### Download the necessary Oscam installation package
echo -n "Downloading the necessary Oscam installation IPK package... "
wget -q -O $TMP_DIR/$IPK_FILENAME $BASE_FEED/$OEVER/$ARCH/$IPK_FILENAME && echo " done." || { echo " failed!"; exit 1; }

#### Extracting the IPK package
extractor() {
    echo -n "Extracting:  $1 $2  --  "; $BIN7Z e -y $1 $2 > /dev/null 2>&1 && echo "OK" || { echo "FAILED!"; exit 1; }
    }
echo "$HR_LINE"
echo "Extracting the IPK package:"
extractor $IPK_FILENAME                          # 1. splitting linked files ("ar" archive) - since "ar" separates files from the archive with difficulty, so I will use "7-zip" archiver
extractor data.tar.?z                            # 2. unpacking the ".gz" OR ".xz" archive
extractor data.tar ./usr/bin/$REQUESTED_BUILD    # 3. unpacking ".tar" archive, but only one file - i.e. an oscam binary file, for example as "oscam-trunk"
echo -n "The Oscam binary file has "
[ -f $TMP_DIR/$REQUESTED_BUILD ] && echo "been successfully extracted." || { echo "not been extracted! Please check the folder '$TMP_DIR'."; exit 1; }
chmod a+x $TMP_DIR/$REQUESTED_BUILD
echo "$HR_LINE"

#### Check the availability of some dependent libraries:
if $TMP_DIR/$REQUESTED_BUILD --build-info 2>&1 | grep -q 'required by'; then
   echo "Unfortunately, some dependent libraries are missed for the Oscam binary file."
   echo "You can try to install / to update them manually ... for example:"
   echo "    opkg update"                       # opkg update > /dev/null 2>&1
   echo "    opkg install libc6 libcrypto1.0.2 libssl1.0.2 libusb-1.0-0"
   echo "$HR_LINE"
   $TMP_DIR/$REQUESTED_BUILD --build-info
   exit 1
fi

#### Check the availability of some sym-links to libraries:
if $TMP_DIR/$REQUESTED_BUILD --build-info 2>&1 | grep -q 'shared libraries'; then
   echo "Unfortunately, some libraries have missed symbolic-links."
   echo "You can try to assign them manually (ln -s file symlink) ... for example:"
   echo "    ln -s /usr/lib/libssl.so.1.0.2 /usr/lib/libssl.so.1.0.0"
   echo "    ln -s /usr/lib/libcrypto.so.1.0.2 /usr/lib/libcrypto.so.1.0.0"
   echo "$HR_LINE"
   $TMP_DIR/$REQUESTED_BUILD --build-info
   exit 1
fi

#### Function to check the Enigma2 Standby
is_standby() {
    #[ "$(wget -qO- http://127.0.0.1/web/powerstate | grep -i '</e2instandby>' | cut -f 1)" = "true" ]
    #[ "$(wget -qO- http://127.0.0.1/web/powerstate | grep -i '</e2instandby>' | awk '{print $1}')" = "true" ]
    #wget -qO- "http://127.0.0.1/api/powerstate" | grep -iqE '"instandby"\s*:\s*true'
    #wget -qO- http://127.0.0.1/web/powerstate | grep -qi 'true'
    wget -qO- http://127.0.0.1/api/powerstate | grep -qi 'instandby.*true'
}

#### Retrieve Oscam online version   (from downloaded binary file)
OSCAM_ONLINE_VERSION=$( $TMP_DIR/$REQUESTED_BUILD --build-info | grep -i 'version:' | grep -o '[0-9]\{5\}' )    # output result is, as example:  11552
#OSCAM_ONLINE_VERSION=$( echo $IPK_FILENAME | sed -e 's/.*svn\([0-9]*\)-.*/\1/'  )                              # old method to retrieve online Oscam version
[ -z "$OSCAM_ONLINE_VERSION" ] && { echo "Error! The online version cannot be recognized! Script canceled!"; exit 1; }

#### Retrieve Oscam local version    (from current binary file placed in the /usr/bin folder)
OSCAM_LOCAL_VERSION=$(  $OSCAM_LOCAL_PATH --build-info | grep -i 'version:' | grep -o '[0-9]\{5\}'   )          # output result is, as example:  11546
[ -z "$OSCAM_LOCAL_VERSION" ] && OSCAM_LOCAL_VERSION="11000"                                                    # sets the null version as a precaution if there is no Oscam binary file on the local harddisk yet

#### Compare Oscam local version VS. online version
echo -e "Oscam version on internet:\t$OSCAM_ONLINE_VERSION\nOscam version on local drive:\t$OSCAM_LOCAL_VERSION"
if [ "$OSCAM_ONLINE_VERSION" -gt "$OSCAM_LOCAL_VERSION" ]
then

    echo "A new version of Oscam has been found and will be updated."
    # wget -qO- "http://127.0.0.1/web/message?type=1&timeout=10&text=New+Oscam+version+found+($OSCAM_ONLINE_VERSION)%0ANew+version+will+updated+now." > /dev/null 2>&1     # show WebGUI info message
    #### Replace the oscam binary file with new one
    OSCAM_BIN_FNAME=${OSCAM_LOCAL_PATH##*/}
    if ps --version 2>&1 | grep -q -i "busybox"; then
        OSCAM_CMD=$(ps | grep $OSCAM_BIN_FNAME | grep -v grep | head -n 1 | grep -o '/.*$')                     # feature-poor `ps` command from BusyBox (for example in OpenPLi image)
    else
        OSCAM_CMD=$(ps -f --no-headers -C $OSCAM_BIN_FNAME | head -n 1 | grep -o '/.*$')                        # full-featured `ps` command from Linux OS (for example in OpenATV image)
    fi
    
    [ -z "$OSCAM_CMD" ] || { killall -9 $OSCAM_BIN_FNAME ; echo "Recognized Oscam command-line: $OSCAM_CMD" ; }
    mv -f $TMP_DIR/$REQUESTED_BUILD $OSCAM_LOCAL_PATH
    chmod a+x $OSCAM_LOCAL_PATH
    
    [ -z "$OSCAM_CMD" ] ||
    { 
    $OSCAM_CMD
    sleep 1
    if pidof $OSCAM_BIN_FNAME > /dev/null 2>&1; then
        echo "The new Oscam is ready to use !"
        #### helping for IRDETO cards to receive any EMMs --- it is to neccessary, to receive some entitlements after each Oscam restart
        if is_standby && [ "$IRDETO_ENTITLEMENTS" = "yes" ]; then
            echo "$HR_LINE"
            echo "Turning on the tuner..."
            echo "...zapping the user specified channel - $IRDETO_CHANNEL"
            wget -qO- "http://127.0.0.1/api/zap?sRef=${IRDETO_CHANNEL}" > /dev/null 2>&1
            echo "...waiting for a while, to receive any entitlements on your IRDETO satellite card"
            sleep 40        # waiting 20 secs for card initialization + 20 secs to receive any EMM
            echo "...turning off the tuner (Enigma still in standby)"
            wget -qO- "http://127.0.0.1/api/zap?sRef=0" > /dev/null 2>&1
            echo "...done !"
        fi
    else
        echo "The new Oscam failed to start ! Exiting the update script !"
        exit 1
    fi
    }

else

    echo "Installed Oscam version is current. No need to update."
    # wget -qO- "http://127.0.0.1/web/message?type=1&timeout=10&text=Installed+Oscam+version+($OSCAM_LOCAL_VERSION)+is+current.%0ANo+need+to+update." > /dev/null 2>&1     # show WebGUI info message

fi

#### Remove all temporary files (sub-directory)
rm -rf $TMP_DIR




echo "$HR_LINE"

exit 0
