#!/bin/bash
# mounts a 1GB ramdisk
# execute as root

#/etc/fstab
#tmpfs	/ramdisk	tmpfs	defaults,size=1G,mode=1777	0	0

pool_dir=/ramdisk

[ -d $pool_dir ] || mkdir $pool_dir
[ -d $pool_dir ] && chmod 1777 $pool_dir

mount -t tmpfs -o size=1G tmpfs /ramdisk


