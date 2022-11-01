#!/bin/sh 
#ramdisk-pool
#
### BEGIN INIT INFO
# Provides:          ramdisk-pool
# Required-Start:    mtab
# Required-Stop:     mtab
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# X-Start-Before:    
# X-Stop-After:      
# Short-Description: sync zfs file pools to ramdisk
# Description: Syncs and imports file based zfs test pools on ramdisk
### END INIT INFO

 case "$1" in
   start)
     echo "Synching files from Harddrisk to ramdisk"
     rsync -v /ramdisk-backup/pool*.img /ramdisk/
     echo [`date +"%Y-%m-%d %H:%M"`] Ramdisk Synched from HD >> /var/log/ramdisk-pool.log
     zpool import pool1 -N -d /ramdisk/pool1.img
     zpool import pool2 -N -d /ramdisk/pool2.img
     ;;
   sync)
     echo "Synching files from ramdisk to Harddisk"
     echo [`date +"%Y-%m-%d %H:%M"`] Ramdisk Synched to HD >> /var/log/ramdisk-pool.log
     rsync -v /ramdisk/pool*.img /ramdisk-backup/
     ;;
   stop)
     echo "Synching files from ramdisk to Harddisk"
     zpool export pool1
     zpool export pool2
     [ -d /ramdisk-backup ] || mkdir /ramdisk-backup
     rsync -v /ramdisk/pool*.img /ramdisk-backup/
     echo [`date +"%Y-%m-%d %H:%M"`] Ramdisk Synched to HD >> /var/log/ramdisk-pool.log
     ;;
   *)
     echo "Usage: /etc/init.d/ramdisk {start|stop|sync}"
     exit 1
     ;;
 esac

 exit 0
