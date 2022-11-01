# utilities (folder)
- some extra utilities  
1. etherwake.sh - fake etherwake for testing 
2. ramdisk_pool.sh - sysv init script to rsync and import file based test pools to and from ramdisk
3. shutdown_server.sh - shutdown server by unpriviliged user ( without sudo ) from roots crontab 

## etherwake.sh
- fake etherwake  
just something to feed to the scripts for $wake_cmd when testing remote functionality  
without actualy sending an etherwake

## zfs-ramdisk_pool.sh
- sysv init style script  
1. to automatily sync file based pools to ramdisk and import the pools
2. and sync back to disk and export before shutdown.

(put in /etc/init.d and run "update-rc.d ramdisk-pool defaults")

## shutdown_server.sh
- shutdown server (without sudo)  
just a shutdown script for roots crontab  
that can be shut down after backup jobs finish  

need to (ssh user@host "echo 1 > /tmp/shutdown") from remote after backup (if pushing or pulling as user)  
(if pulling as root , can shutdown itself from crontab after script)
