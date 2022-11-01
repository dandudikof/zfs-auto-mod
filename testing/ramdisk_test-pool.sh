#!/bin/bash
# mounts a 1gig ramdisk and creates 2 file based pools
# execute as root

#/etc/fstab			(for ramdisk file based test pools)
#tmpfs	/ramdisk	tmpfs	defaults,size=1G	0	0
#or manualy >

[ -d /ramdisk ] || mkdir /ramdisk
mount -t tmpfs -o size=1G tmpfs /ramdisk

pool_dir=/ramdisk

dd if=/dev/zero of=$pool_dir/pool1.img bs=1M count=450 status=progress
dd if=/dev/zero of=$pool_dir/pool2.img bs=1M count=450 status=progress

zpool create -m none pool1 $pool_dir/pool1.img 
zpool create -m none pool2 $pool_dir/pool2.img


