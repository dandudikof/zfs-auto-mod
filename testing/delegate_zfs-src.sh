#!/bin/bash
# delegate minimal zfs permissions nedded for running scripts to unpriviliged user for test pools
# execute as root

[ -z $1 ] && { echo "error, no user name"; exit 1; }

user="$1"

src_pool=pool1



#source pool
zfs allow -u "$user" create,destroy,send,mount,snapshot,hold,userprop $src_pool


