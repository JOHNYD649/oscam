#!/bin/sh
sed "s/, /\n/g;s/ = / -> /;s/=//g;s/^ /Used: /;s/ on /\n/;s/ECM//;s/ID /ID: /;\
  s/pid/Pid: /;s/cw\(*.\):/cw\1\:  /g" /tmp/ecm.info
echo "------------------------------------------------------------------"
sed "s/^ //;s/->/\n    /g" /tmp/pid.info
echo "------------------------------------------------------------------"
cat /tmp/mgstat.info | sed "s/gbox route //"
