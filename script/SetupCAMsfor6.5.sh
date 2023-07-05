#!/bin/sh

echo "Fixing old CAM feeds and setting up new for 6.5+ images..."
echo
echo "a) removing existing cams"
opkg update
opkg remove --nodeps enigma2-plugin-camd-oscam-emu enigma2-plugin-camd-oscam-emu-ccache enigma2-plugin-camd-oscam-latest enigma2-plugin-camd-oscam.emu-latest enigma2-plugin-camd-oscam-latest enigma2-plugin-camd-oscam-latestipv6 enigma2-plugin-camd-oscam-pcscd-latest

echo "b) setting new feeds"
opkg install --force-reinstall enigma2-plugin-external-extra-feed

echo "c) update..."
opkg update

echo "d) install oscamemu"
opkg install enigma2-plugin-camd-oscam-emu

echo "Please install more cams as needed and restart"

