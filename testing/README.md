
# testing/*
utilities for testing/development of the zfs-auto-mod scripts.  

or a quick way to learn about all functions of the scripts

*(stop/disable zfs-zed to to save ssd-flash drives from excessive logging)*  

# usage

(run all from within testing/ folder)  

run as root  
`./create_ramdisk.sh`  
`./create_test-pools.sh`  
`./delegate_zfs-src.sh myuser`  
`./delegate_zfs-dest.sh myuser`  
 
run as root or user if delegated  
`./create_test-sets.sh`  
`./exec_date-count.sh`  

reset before next run  
`./reset_date-count.sh`

*(../config/type[1,2].cfg are configured for test runs of exec_date-count.sh)*  

### create_ramdisk.sh
- create a 1GB /ramdisk tmpfs in memory

### create_test-pools.sh
- create and import file based test pools on /ramdisk for testing purposes.  
	*(for speed and more importantly, to save ssd/flash based drives from excessive writes)*  
	1. creates 450MB each pool1.img and pool2.img files  
	2. creates pool1 on pool1.img and pool2 on pool2.img  

### delegate_zfs-src.sh myuser  
- delegate minimal zfs permissions to a non-root user for src test pool1

### delegate_zfs-dest.sh myuser  
- delegate minimal zfs permissions to a non-root user for dest test pool2  

### create_test-sets.sh
- creates a dataset structure for testing on pool1  
	and sets zfs properties on datasets

### exec_date-count.sh

- test run simulated schedule on scripts.  
	1. run a test schedule using ../config/type1.cfg and ../config/type2.cfg  
	2. with optional pausing steps at various intervals of week day and hour.  
	3. create logging directories and files (to allow tailing before scripts first iteration)
	 	
	*(peek inside first)*
	
	**execute**
	`./exec_date-count.sh`
	*(defaults to  paused state at start)*
	
	*now ideally start tailing `tail -f /ramdisk/log/backup.log` to see what is going on (in another terminal)*  
	*also start tailing `tail -f /ramdisk/log/send.log` to see what zfs send is doing (in another terminal)*  
	
	**then hit run or step**  
	*(another terminal or desktop buttons)*  
	`echo run > /tmp/auto-pause`		#run  
	`echo step1 > /tmp/auto-pause`	#step hourly  
	`echo step2 > /tmp/auto-pause`	#step daily  
	`echo step3 > /tmp/auto-pause`	#step weekly  
	`echo pause > /tmp/auto-pause`	#pause  
	
	`grep -n ERR /ramdisk/log/backup.log` *will show both STDERR(s) and script generated ERROR(s)*  

### reset_date-count.sh 
- destroy all snapshots on pool1 and backups created on pool2 by test run  
	*(but will not touch manually created snapshots on pool1)*

