#!/bin/bash
# creates a dataset structure and sets $zfs user properties on sets for testing
# execute as user after $zfs-deligate.sh

zfs=/sbin/zfs 
# or add /sbin to $PATH of regular user

#for snap type1
$zfs create pool1/type1
$zfs create pool1/type1/container
$zfs create pool1/type1/container/dataset1
$zfs create pool1/type1/dataset1
$zfs create pool1/type1/dataset1/dataset1
$zfs create pool1/type1/excluded
$zfs create pool1/type1/excluded/dataset1
$zfs create pool1/type1/parent
$zfs create pool1/type1/parent/dataset1

$zfs set auto:incl=c pool1/type1/container
$zfs set auto:excl=1 pool1/type1/excluded
$zfs set auto:incl=p pool1/type1/parent

#for snap type2
$zfs create pool1/type2
$zfs create pool1/type2/container
$zfs create pool1/type2/dataset1
$zfs create pool1/type2/dataset2
$zfs create pool1/type2/dataset3
$zfs create pool1/type2/excluded
$zfs create pool1/type2/parent


$zfs set auto:incl=c pool1/type2/container
$zfs set auto:incl=d pool1/type2/dataset1
$zfs set auto:incl=d pool1/type2/dataset2
$zfs set auto:incl=d pool1/type2/dataset3
$zfs set auto:incl=p pool1/type2/parent

#do not take hourlies
$zfs set auto:nsnap:h=0 pool1/type2/dataset2
#do not take dailies and hourlies
$zfs set auto:nsnap:d=0 pool1/type2/dataset3
$zfs set auto:nsnap:h=0 pool1/type2/dataset3



