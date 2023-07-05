#!/bin/sh
# skrypt wyswietla informacje o fizycznych kartach w aktywnych readerach

clear

rm -rf /tmp/entitlements.txt

oscam_version_file=$(find /tmp/ -name oscam.version | sed -n 1p)
if ! test $oscam_version_file; then echo "Pliku oscam.version nie ma w katalogu /tmp. Najpierw uruchom oscam-a a dopiero potem ten skrypt, BYE!"; exit 0; fi

oscam_config_dir=$(grep -ir "ConfigDir" $oscam_version_file | awk -F ":      " '{ print $2 }')
oscam_httpuser=$(grep -ir "httpuser" $oscam_config_dir"oscam.conf" | awk -F "=" '{ print ($2) }' | sed 's/^[ \t]*//')
oscam_httppwd=$(grep -ir "httppwd" $oscam_config_dir"oscam.conf" | awk -F "=" '{ print ($2) }' | sed 's/^[ \t]*//')
oscam_httpport=$(grep -ir "httpport" $oscam_config_dir"oscam.conf" | awk -F "=" '{ print ($2) }' | sed 's/^[ \t]*//')
protocol=$(if echo $oscam_httpport | grep + >/dev/null; then echo "https"; else echo "http"; fi)
mywget=$(if [ -s /usr/bin/fullwget ]; then echo "fullwget"; else echo "wget"; fi)
cert=$(if [ "$protocol" = "https" ]; then echo "--no-check-certificate"; fi)
port=$(echo $oscam_httpport | sed -e 's|+||g')
access=$(if [ -n "$oscam_httpuser" ] && [ -n "$oscam_httppwd" ]; then echo "$oscam_httpuser:$oscam_httppwd@"; fi)

$mywget $cert -qO- "$protocol://$access"127.0.0.1":$port/status.html" | grep "Restart Reader" | sed -e 's|<TD CLASS="statuscol1"><A HREF="status.html?action=restart&amp;label=||g' | sed 's/^[ \t]*//' | awk -F "\"" '{ print ($1) }' >/tmp/active_readers.tmp

while IFS= read -r line; do
$mywget $cert -qO- "$protocol://$access"127.0.0.1":$port/readers.html?action=reread&label="$line"" >/dev/null
sleep 5
$mywget $cert -q "$protocol://$access"127.0.0.1":$port/entitlements.html?label="$line"" -O /tmp/"$line"_entitlements.html
serial=$(cat /tmp/"$line"_entitlements.html | grep "id=\"serialDiv\"" | awk -F "[<>]" '{ print ($5) }')
if [ "$serial" != "00 00 00 00" ] && [ "$serial" != "00 07 98 00" ]; then
cardsystem=$(cat /tmp/"$line"_entitlements.html | grep "\<TD COLSPAN=\"1\">" | awk -F "[<>]" '{ print ($5) }')
validto=$(cat /tmp/"$line"_entitlements.html | grep "\<TD COLSPAN=\"1\">" | awk -F "[<>]" '{ print ($9) }')
ird=$(cat /tmp/"$line"_entitlements.html | grep "\<TD COLSPAN=\"1\">" | awk -F "[<>]" '{ print ($13) }')
maturity=$(cat /tmp/"$line"_entitlements.html | grep "\<TD COLSPAN=\"1\">" | awk -F "[<>]" '{ print ($17) }')
provider_sa=$(cat /tmp/"$line"_entitlements.html | grep "\<BR>$" | sed -e 's/<[^>]*>/ /g' | sed -e 's/^.*   //g' | sed '2,$ s/^/                /')
atr=$(cat /tmp/"$line"_entitlements.html | grep "\<TD COLSPAN=\"4\">" | awk -F "[<>]" '{ print ($7) }')
rom=$(cat /tmp/"$line"_entitlements.html | grep "\<TD COLSPAN=\"4\">" | awk -F "[<>]" '{ print ($3) }')
rights=$(cat /tmp/"$line"_entitlements.html | grep "\<TR CLASS=" | grep "\<TD><TD>" | sed 1d | sed 's/package/pack/g' | sed -e 's/<[^>]*>/ /g' | sed 's/^[ \t]*//')
echo "-----------------------------------------------------------------------------------------------------
Reader Name:    $line
Cardsystem:     $cardsystem
Valid To:       $validto
IRD ID (nagra): $ird
Maturity:       $maturity
Rom:            $rom
ATR:            $atr
Serial:         $serial
Provider - SA:  $provider_sa
-----------------------------------------------------------------------------------------------------
Type  Caid  Provid         ID          Class      Start       Expire           Name
-----------------------------------------------------------------------------------------------------
$rights
-----------------------------------------------------------------------------------------------------" >>/tmp/entitlements.txt
fi
done < /tmp/active_readers.tmp

if [ -s /tmp/entitlements.txt ]; then cat /tmp/entitlements.txt; else echo "Aktualnie brak aktywnych kart"; fi

rm -rf /tmp/*.tmp /tmp/*.html /tmp/entitlements.txt


