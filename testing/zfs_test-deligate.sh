#!/bin/bash
# deligate minimal zfs permissions nedded for running scripts to unpriviliged user for test pools
# execute as root

user="changeme"

#source pool
zfs allow -u $user create,destroy,mount,send,snapshot,hold,userprop pool1

#destination pool
zfs allow -u $user create,destroy,receive,mount,mountpoint,userprop,rollback pool2


