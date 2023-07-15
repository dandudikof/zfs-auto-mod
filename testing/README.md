# testing
- utilities for testing/development of the zfs-auto-mod scripts  

(or a good way to quickly learn about all functions of the scripts,  
for more advanced users, instead of waiting hours,days,weeks for crontabs to run)

(run all from within testing/ folder)
(stop/disable zfs-zed to to save ssd-flash drives from excessive logging)


1. date_count.sh - test run simulated schedule on scripts hours/days/weeks/months etc...  
2. ramdisk_test-pool.sh - sets up ramdisk and creates file based test pools.
3. ramdisk_test-sets.sh - creates test datasets on said pools and sets zfs properties needed for testing.
4. reset_test-backup.sh - cleans up snapshots on pool1 and deletes whole pool2/d_path after test runs.
5. zfs_test-deligate.sh - give minimal zfs access (zfs allow) to an unpriviliged user to run scripts on test pools.


# usage 

	- run ramdisk_test-pool.sh (as root) to create test pools
	- run zfs_test-deligate.sh (as root) if testing scripts as unprivileged user (change $user)
	- run ramdisk_test-sets.sh to ceate test dataset structure and set zfs user properties

*	run date_count.sh (peek inside before you do) 
	*config/type[1,2].cfg are ready for test runs of date_count.sh on test pools*
	
(to run zfs commands from cli as a user, like setting zfs properties or creating datasets etc...)  
(add /sbin to $PATH or softlink to /sbin/zfs from ~/bin/zfs if in users $PATH)

## date_count.sh 
- test run simulated schedule on scripts.  
with optional pausing steps at various intervals of week day and hour.  
all script files and configs can be edited while running date_count.sh.  
(but pausing steps are advised to check the logs and created snapshots/backups)  

*idealy tailing (tail -f backup.log) to see what is going on*  
*also tailing (tail -f send.log) to see what zfs send is doing*  

([STDERR] will show up on first backup runs for unprivileged users as they cannot mount zfs sets,  
but watch for them later as they indicate something else, like not enough zfs permissions to the user  
for something like sending over mountpoint or compression property without zfs permissions to do so.  
or some other issues etc.... )

(grep -n ERR backup.log) will show both STDERR(s) and script generated ERROR(s)

## ramdisk_test-pool.sh
- create file based test pools for testing purposes  
	- on a ramdisk for faster speed during test runs  
	- and more importantly , to save ssd/flash based drives from excessive writes  
	- especialy when running years/decades/centuries worth of snapshots/backups tests  

## ramdisk_test-sets.sh
- create a dataset tree for testing 
and set zfs properties on datasets 

## reset_test-backup.sh 
- destroy all snapshots and backups created by test run of date_count.sh 
but will not touch manualy created snapshots on source (remove them manualy)

## zfs_test-deligate.sh
- deligate zfs permissions to a user for test pools (change $user)


