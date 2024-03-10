#!/bin/bash
# creates 2 file based pools
# execute as root




pool_dir=/ramdisk

dd if=/dev/zero of=$pool_dir/pool1.img bs=1M count=450 status=progress
dd if=/dev/zero of=$pool_dir/pool2.img bs=1M count=450 status=progress

zpool create -m none pool1 $pool_dir/pool1.img 
zpool create -m none pool2 $pool_dir/pool2.img


