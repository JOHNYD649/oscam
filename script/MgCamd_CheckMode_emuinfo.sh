#!/bin/sh
echo "          **Show current mode...**  "
grep 'G' /usr/keys/mg_cfg >/tmp/cur_mode
echo "          **Current Mode!!!**  "
tail /tmp/cur_mode


