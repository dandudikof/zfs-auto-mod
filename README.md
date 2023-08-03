# zfs-auto-mod
Bash based, modular, ZFS snapshot,replicate and prune scripts.  
Local and remote execution, pull or push replication.  
Which can be used together or independantly.  

## mission
Support (open-zfs) on linux and freebsd.  

Focus on simple, clean, not too convoluted coding style without excessive nesting  
and function recursioning, for easier readability and maintanability of the code.  

_(Bash chosen for cleaner, more compact code, with arrays, indirect expansions,  
parameter expansion options, and other bash specific tricks)_
	
## notes (beta)
* initial release, even though i have been using it for a few years, consider it (beta).  
* only tested on devuan/debian/freebsd so far (but assume debian/freebsd based (other?) dists should work).  
* besides bash and crontab  
	cat,tac,date,grep,sed,tail,head,ps,printf,(ssh,ping,etherwake or wakeonlan) are used is the scripts.  
* tagged v1.00.00 (will branch for fixes)  
* working towards v1.01.00 (freezing features)

_(untill i see or hear of some outside interest in this repository,  
	i will reserve the right to rebase and force push, down to last release tag)_

# scripts (descriptions)
each script can run commands localy or remotely (src or dest or both)

### zfs_auto_snap.sh (2 types of snapshots)
will snapshot all sets classified as (dataset) based on snap_type

1. (snap_type 1) simple snapshots , will take snapshots whenever called (run up to hourly)  
	```
	pool1/type1/dataset1@auto_t1_2025-05-01_00:20:00-n77
	pool1/type1/dataset1@auto_t1_2025-05-01_01:20:00-n78
	pool1/type1/dataset1@auto_t1_2025-05-01_02:20:00-n79
	```
	- with optional (recursive) minws option for minimal written size before snapshot is taken.  
	`zfs set pfix:minws=[bytes] pool/dataset`(change pfix and bytes) (omit [ ])  

2. (snap_type 2) takes monthly weekly daily hourly (run up to hourly)  
	
	- first snapshot of the month takes a monthly snapshot.  
	- first snapshot of the week takes a weekly snapshot.  
	- first snapshot of the day takes a daily snapshot.  
	- all others snapshots taken are hourly snapshots.  
	```
	pool1/type2/dataset1@auto_t2_2025-05-01_00:20:00-m
	pool1/type2/dataset1@auto_t2_2025-05-01_01:20:00-w
	pool1/type2/dataset1@auto_t2_2025-05-01_02:20:00-d
	pool1/type2/dataset1@auto_t2_2025-05-01_03:20:00-h
	```
	- with optional (recursive) nsnap option for finer grained snapshot controll of  
		whether not to take (monthly weekly daily hourly) snapshots  
		`zfs set pfix:nsnap:[m,w,d,h]=[0,1] pool/dataset`(change pfix, one of mwdh, 0 or 1) (omit [ ])  
	- with optional (recursive) minws option for minimal written size before snapshot is taken.  
		when written size reaches set value for (monthly weekly daily hourly) take snapshot  
		`zfs set pfix:minws:[m,w,d,h]=[bytes] pool/dataset`(change pfix, one of mwdh, and bytes) (omit [ ])  
	
3. (parent) will also snapshot dataset@$pfix-parent for s_pool and parent datasets (once)  
	(patent snapshot can be deleted on src and dest to force script to take  
	another @pfix-parent snapshot and to force a resend to transfer new zfs set properties).

### zfs_auto_bak.sh 
will replicate specified datasets to destination(s).

1. sorts backup list in correct order (backup children after parents ...)
2. creates destination path on dest (d_path, maybe hostname of src?) 
3. creates (container) sets on dest (empty sets for organisation only)
4. replicates (parent) sets to dest (empty sets for organisation and zfs properties transfer)
5. replicates (dataset) sets to dest (data sets with script created and other snapshots)

(avoid storing data in s_pool and other parent datasets)  

- with option for secondary backup destination(s)  
1. duplicate config with d_type=sec and new destination settings, and run backup/prune-dest again  
(sec destinations does not set pfix:tsnum, as source prune only checks against a single primary)  
(pfix:tsnum stops source from pruning snapshots not yet transfered to primary destination)  
(run secondary backups after primary but before source prunes,  
so that same snapshots transfer to secondary(s))  
(with new config file)

2. or make destination also a source for a new primary destination and run backup and prune-dest again  
(now executing only backup/prune-dest scripts on a new source if pushing or new destination if pulling)  
(new config file)

### zfs_auto_prune-[src,dest].sh 
will prune source or destination snapshots (based on snap_type) and config options  
(manualy created or any other snapshots which were not crated by script/config remain untouched)

- with option for just snapshot or snapshot and prune-src (s_type=sp) without backup  
(will prune as specified by config)(without pfix:tsnum checks)

- or snapshot, backup, prune-src and prune-dest (s_type=sbp) backup enabled  
(with pfix:tsnum checks)(will avoid pruning src snapshots not yet transfered to primary destination)

# functions (used by each script)

### fnc_logging.sh
logging functionality of the script (does not depend on system logging)

- creates logging directories and files.
- assigns logging channels to functions or files.
- chooses what to log based on verbosity of config
- some editing and cleaning of logging data (like trimming/formating zfs send output)

(rotations of logfiles needs to be setup separatley with logrotate)  
(unprivileged user must have write permission if logging to /var/log/$pfix)

### fnc_sort-list.sh (2 types of sorts)
builds arrays of sets based on supplied s_pool or s_pool/s_sets if set, that scripts act on.

(s_pool always treated as a parent. not for data)
(if s_sets is not set whole s_pool is searched)

1. (sort_type 1) auto inclussive sort  
	will treat everything under s_pool or s_pool/s_sets as datasets.  
	**and** all children(recursive) of (container,parent,dataset) as datasets.  
	unless set as excluded(recursive) or as a parent or container.  
	
	(s_sets themselves are set by set_type option in config file  
	and can be overriden by pfix:incl zfs property)  

2. (sort_type 2) manual sort  
	everything under s_pool or s_pool/s_sets **must**  
	be set as container,parent,dataset including s_sets  
	
	(s_sets themselves **must** be set as a container,parent or dataset)  
	everything else excluded.  

(optional, no need to set unless that functionality is needed or using sort type2)  
`zfs set pfix:incl=[c,p,d] pool/dataset`(change pfix, pick one c,p,d) (omit [ ])  
`zfs set pfix:excl=1 pool/dataset`(change pfix)

- (container) incl d_path do not get transfered during backups but simply recreated on dest (as path objects)
- (parent) gets a set@pfix-parent snapshot and is transfered once on first backup (to transfer zfs properties)
- (dataset) gets a snapshots based on snap_type and is alway transfered and pruned
- (excluded) excludes the set itself and all children from all operations (snap,back,prune)

* basic debug is enabled with verblist=1 in config file
(will log a list of of all sets and classifications they recieved)

### fnc_remote-check.sh
ping checks source and destination if set as remote. and sends a wake_cmd if configured
1. just to check if remote server is reachable before starting script 
2. wake up remote server if needed , wait for server to come up and continue script
3. if remote source or destination is unreachable send ERROR to log and stop script

### fnc_pool-check.sh
checks the health status of the s_pool and d_pool
1. if pool is ONLINE, continue script 
2. if DEGRADED,SUSPENDED,UNAVAIL etc.. send an ERROR to the log and stop script

### fnc_lock-check.sh
locking on a peer script peer config file basis  
1. checks for an existing lock for current script and current config file
2. checks if it may be a stale lock, process no longer running (clears them)
3. checks if if pid of locking script was not stolen by some other process
4. creates new locks if none exist
5. clears locks when done

(can run same script with different configs or other scripts with same config at same time)  
(ie - will stop another backup on same config if old one has not finished, but can still snap/prune,  
but not prune not yet transfered snapshots as that is handled by tsnum)

# install (no packaging yet)
simply git clone to your $HOME directory  
`git clone https://github.com/dandudikof/zfs-auto-mod.git`  
(if cloned somwhere else, edit $script_dir to correct location in /config/*.cfg files)  
- FreeBSD  
1. Needs a softlink /bin/bash to point to /usr/local/bin/bash (or change shebangs to #!/usr/bin/env bash)  
2. Needs /var/run/lock/zfs-auto-mod created (and be writable by user/group that is using the scripts)  
3. Needs logging dir created (and be writable by user/group that is using the scripts)  
4. if Testing /ramdisk/auto dir created (and be writable by user/group that is using the scripts)  
5. Keep the portability/shim function for tac in the config file  

# usage
execution is a simple (/path_to/script.sh /path_to/simple.cfg) no flags  

1. simple local snapshot,backup,prune 
```
#simple.cfg (minimal settings needed for a local snap/back prune)

script_dir=~/zfs-auto-mod #do NOT double quote. #otherwise use $HOME instead of ~
zfs=/sbin/zfs
zpool=/sbin/zpool

pfix="auto"
sort_type=1
snap_type=1
set_type=d

s_zfs="$zfs"
s_pool="pool1"
s_sets=""
s_type=sbp
s_k=12

d_zfs="$zfs"
d_pool="pool2"
d_path="pool2/auto"
d_type=pri
d_k=24

verbose=1
log_dir=/tmp/$pfix
log_file3=$log_dir/backup.log
log_file6=$log_dir/send.log

DATE=$(date +%Y-%m-%d); TIME=$(date +%T)
Yn=$(date +%Y); my=$(date +%m); wy=$(date +%W)
dy=$(date +%j); dm=$(date +%d); dw=$(date +%u)
hd=$(date +%H)
```

```
# users crontab
55 * * * * ~/zfs-auto-mod/zfs_auto_snap.sh ~/zfs-auto-mod/config/simple.cfg
56 23 * * * ~/zfs-auto-mod/zfs_auto_bak.sh ~/zfs-auto-mod/config/simple.cfg; ~/zfs-auto-mod/zfs_auto_prune-src.sh ~/zfs-auto-mod/config/simple.cfg; ~/zfs-auto-mod/zfs_auto_prune-dest.sh ~/zfs-auto-mod/config/simple.cfg
# crontab does not allow line splitting (better use launcher scripts)
```
- on 55th minute of every hour. will take snapshots of every set under pool1 (recursevly)  
- on 56th minute of 23rd hour. replicate them to pool2/auto
	- after backup finished. prune source leaving only s_k=12 snapshots 
	- after prune-src finished. prune destination leaving only d_k=24 snapshots 
	
## restoring (back to source)
is done with ((ssh user@host) zfs send |(ssh user@host) zfs recv)  
(lots of documentation online for this procedure, and is essential to know when working with zfs) 

- any user set zfs properties originaly being source=local become source=received  
	after any send|recv procedures (forever it seems)
	1. can be set again to get source=local to hide received.  
	but (zfs inherit -S property) can restore back to hidden received.
	2. can be dumped with -x property during send|recv and set again for posterity.  
	to get source=local without a hidden received.
	3. can be ignored, as scripts deals with both local and received  
	(recieved only on destination or after restore).

### caveats
1. a few [STDERR] from zfs are normal during first backups  
(as an unprivileged user can create dataset but not mount)  
(and errors about clone set send and encryption property even if encryption not used, zfs bug reported)
2. root operation not necessary, but is needed for pool creation and initial zfs deligation  
(look at testing/zfs_test-deligate.sh for minimal zfs permissions needed for unpriviliged user)
3. Remote source or destination require ssh be configured with paswordless/pubkey login (ssh-copy-id or manualy)
4. Multiple config executions can log to the same log files but only if not ran concurrently  
5. While simpler uses of the scripts rely only on a single config file.  
	- Extended control is achieved trough setting zfs user properties on sets
		1. pfix:incl=[c,p,d] (optional) sets dataset classification type container, parent or dataset
		2. pfix:excl=1 (optional,recursive) sets dataset and all children as exluded from all operations
		3. pfix:minws=[bytes] (optional,recursive) sets minimal bytes written before snapshot (snap_type 1 option)  
		(can override inherited settings on children back to 0 or another size)
		4. pfix:nsnap:[m,w,d,h]=[0,1] (optional,recursive) chooses which snapshots to take (snap_type 2 option)  
		(no need to set if doing all. 0 to disable some, 1 only needed to overwrite inherited 0 on children)
		5. pfix:minws:[m,w,d,h]=[bytes] (optional,recursive) chooses when snapshots is taken (snap_type 2 option)  
		(takes snapshots only when written size on set reaches minws)
	- Or multiple executions with different config files and different s_sets
	- And or different pfixes (can intermingle multiple configs withing same dataset structure)
6. Destination pruning depends on source being available (server online) as the set list is created based on  
	sources config, sources zfs listing and and sources zfs user set properties(if used)(prune dest after backups).
7. Script uses international date format year/month/day internally  
(but snapshot names and looging headers can be changed with $DATE in *.cfg)
8. System date/time should be correct at all times (ntpdate on boot and periodicaly wont hurt)  
(snaps will not be taken if date/time snapshot already exists, backups should not be affected,  
and prune is based on amount of specific snapshots to keep not dates/times)
9. Snap script will not take anything more frequent then hourly at the moment.
10. If you are using spaces/tabs in set names (this script is not for you)

# recent (developments)
1. zfs volumes (a fix and tested)  
2. zfs clones (feature and tested)  
3. cleaned up logging (in all levesl of verbosity)  
4. added extra debug and info messages  
5. merged sort type 1 and 2 , moved type 3 to 2 (kept all functionality)  
6. removed snap type 2 , moved type 3 to 2 (kept all functionality)  
7. added written size option to snap type2 (on a separate m w d h setting)  
8. check to force parent snapshot resend (to retransfer new zfs set properties)  
9. clone of clone re-sort (for correct order of clone of clone backups)  
10. initial FreeBSD fixes (feature and tested)  
11. (more in CHANGELOG or commit messages)

# planned (functionality)
1. transport mechanisms besides ssh (planing)
2. zfs bookmarks (have not looked in to yet)
3. zfs encrypted dataset (have not looked in to yet)
4. specifying initial dataset search further down the tree (thinking)
	1. right now list is created right under first level of s_pool or s_pool/s_sets
	- to narrow down further use container/exclude sets for now
	- reorganize pool in to managable sections (ideal)
	- multiple config executions with diferent s_sets
	- and or multiple pfixes with different excluded sets for each
	- and or sharing same container sets (parents need testing)
	- etc...
5. frequent(continuos) snapshotting and replication (pondering)
	- an edge case
	- if not planned or done right, (can get messy)



