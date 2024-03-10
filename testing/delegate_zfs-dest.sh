#!/bin/bash
# delegate minimal zfs permissions nedded for running scripts to unpriviliged user for test pools
# execute as root

[ -z $1 ] && { echo "error, no user name"; exit 1; }

user="$1"

dest_pool=pool2



#destination pool
zfs allow -u "$user" create,destroy,receive,mount,mountpoint,userprop,rollback $dest_pool


