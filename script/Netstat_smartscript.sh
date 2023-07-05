#!/bin/sh
#DESCRIPTION=It shows internet status connection
netstat | grep tcp
netstat | grep unix