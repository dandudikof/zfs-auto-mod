# zfs-auto-mod
Bash based, modular, ZFS snapshot,replicate and prune scripts.  
Local and remote execution, pull or push replication.  
Which can be used as a system or independantly.  

## mission
Support (open-zfs) initially on linux . (freebsd testing planned).  

Focus on simple, not too convoluted coding style without excessive nesting  
and function recursioning, for easier readability and maintanability of the code.  

## notes (beta)
* initial release, even though i have been using for a few years, consider it (beta).  
* only tested on devuan/debian so far (but assume debian based (other?) diststributions should work).  
* besides bash crontab,date,grep,sed,tail,head,(ssh,ping,etherwake or wakeonlan) are used is the scripts.  

# scripts (descriptions)
each script can run commands localy or remotely.  

### zfs_auto_snap.sh (3 types of snapshots)
will snapshot all sets classified as (dataset) based on snap_type

1. (snap_type 1) simplest snapshots , will take snapshots whenever called (run up to hourly)  
	```
	pool1/type1/dataset1@auto_t1_25-05-01_00:20:00-n77
	pool1/type1/dataset1@auto_t1_25-05-01_01:20:00-n78
	pool1/type1/dataset1@auto_t1_25-05-01_02:20:00-n79
	```
	with optional (recursive) check for minimal written size before snapshot is taken.  
	`zfs set pfix:minws=[bytes] pool/dataset`(change pfix and bytes)
	
2. (snap_type 2) simple monthly weekly daily snapshots. (run daily)  
	- if first day of the month takes a monthly snapshot.  
	- if first day of the week takes a weekly snapshot.  
	- all others snapshots are daily snapshots.  
	```
	pool1/type2/dataset1@auto_t2_25-05-01_00:20:00-m
	pool1/type2/dataset1@auto_t2_25-05-02_00:20:00-w
	pool1/type2/dataset1@auto_t2_25-05-03_00:20:00-d
	```
3. (snap_type 3) takes monthly weekly daily hourly (run up to hourly)  
	
	- if first snapshot of the month takes a monthly snapshot.   
	- if first snapshot of the week takes a weekly snapshot.  
	- if first snapshot of the day takes a daily snapshot.  
	- all others snapshots taken are hourly snapshots.  
	```
	pool1/type3/dataset1@auto_t3_25-05-01_00:20:00-m
	pool1/type3/dataset1@auto_t3_25-05-01_01:20:00-w
	pool1/type3/dataset1@auto_t3_25-05-01_02:20:00-d
	pool1/type3/dataset1@auto_t3_25-05-01_03:20:00-h
	```
	with optional (recursive) check for finer grained snapshot controll of  
	whether not to take (monthly weekly daily hourly) snapshots of current sets  
	`zfs set pfix:nsnap:[m,w,d,h]=[0,1] pool/dataset`(change pfix)
	
4. (parent) will also snapshot dataset@$pfix-parent for s_pool and parent datasets(once)

### zfs_auto_bak.sh 
will replicate specified datasets to destination(s).

1. sorts backup list in correct order (backup children after parents ...)
2. creates destination path on dest (d_path, maybe hostname of src?) 
3. creates (container) sets on dest (empty sets for organisation only)
4. replicates (parent) sets to dest (empty sets for organisation and zfs properties transfer)
5. replicates (dataset) sets to dest (data sets with script created and other snapshots)

(avoid storing data in s_pool and parent datasets)  
(if data is stored in s_pool or parent datasets it will be transfered once on first backup)

- with option for secondary backup destinations  
1. duplicate config with d_type=sec and new destination settings, and run backup/prune-dest again)  
(sec destinations does not set pfix:tsnum, not to confuse source prune which only checks against a single primary)  
(run secondary backups after primary but before source prunes, so that same snapshots make it over to secondary(s))

2. or make destination also a source for a new primary destination and run backup and prune-dest again
(now executing scripts on new source if pushing or new destination if pulling)

### zfs_auto_prune-[src,dest].sh 
will prune source or destination snapshots (based on snap_type) and config options  
(manualy created snapshots untouched)

- with option for just snapshot or snapshot and prune-src (s_type=sp) without backup  
(will prune as specified by config)

- or snapshot, backup, prune-src and prune-dest (s_type=sbp) backup enabled  
(will avoid pruning src snapshots not yet transfered to primary dest)

# functions (used by each script)

### fnc_logging.sh
logging functionality of the script (does not depend on system logging)

- creates logging directories and files.
- assigns logging channels to functions or files.
- chooses what to log based on verbosity of config
- some editing and cleaning of logging data (like trimming/formating zfs send output)

(rotations of logfiles needs to be setup separatley with logrotate)
(unprivileged user must have write permission if logging to /var/log/$pfix)

### fnc_sort-list.sh (3 types of sorts)
builds arrays of sets based on supplied s_pool or s_pool/s_sets if set, that scripts act on.

(s_pool always treated as a parent. not for data)

1. (sort_type 1) auto dataset  
	will treat everything under s_pool **including** s_pool/s_sets as datasets.**and**  
	all children(recursive) of (container,parent,dataset) as datasets.  
	unless set as excluded(recursive).  
	(s_sets themselves **can** be set if not a dataset ie container or parent)	
2. (sort_type 2) auto parent  
	will treat s_pool **and** s_pool/s_sets as parents **and**  
	all children(recursive) of (container,parent,dataset) as datasets.  
	unless set as excluded(recursive).  
	(s_sets themselves **can** be set if not a parent ie container or dataset)
3. (sort_type 3) manual sort  
	everything under s_pool or s_pool/s_sets **must**  
	be set as container,parent,dataset including s_sets  
	(s_sets themselves **must** be set as a container,parent or dataset)
	everything else excluded.  
	
	
`zfs set pfix:incl=[c,p,d,e] pool/dataset`(change pfix)
	
- (container) sets do not get transfered during backups but simply recreated on destination (as path objects)
- (parent) gets a set@pfix-parent snapshot and is transfered once on first backup (to transfer zfs properties)
- (dataset) gets snapshots based on snap_type and is alway transfered fully
- (excluded) excludes the set itself and all children from all operations (snap,back,prune)
	
### fnc_remote-check.sh (2 functions )
ping checks source and destination if set as remote. and sends a wake_cmd if configured
1. just to check if remote server is reachable before starting script 
2. wake up remote server if needed , wait for server to come up and continue script

# install (no packaging yet)
simply git clone to your $HOME directory  
`git clone https://github.com/dandudikof/zfs-auto-mod.git`  
(if cloned somwhere else, edit $script_dir to correct location in /config/*.cfg files)  

# usage
execution is a simple (/path_to/script.sh /path_to/simple.cfg) no flags  

1. simple local snapshot,backup,prune 
```
#simple.cfg (minimal settings needed for a local snap/back prune)

script_dir=~/zfs-auto-mod #do NOT double quote. #otherwise use $HOME instead of ~
zfs=/sbin/zfs

pfix="auto"
sort_type=1
snap_type=1

s_zfs="$zfs"
s_pool="pool1"
s_sets=""
s_type=sbp
s_k=12

d_zfs="$zfs"
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
55 23 * * * ~/zfs-auto-mod/zfs_auto_bak.sh ~/zfs-auto-mod/config/simple.cfg; ~/zfs-auto-mod/zfs_auto_prune-src.sh ~/zfs-auto-mod/config/simple.cfg; ~/zfs-auto-mod/zfs_auto_prune-dest.sh ~/zfs-auto-mod/config/simple.cfg
# crontab does not allow line splitting (better use launcher scripts)
```
- on 55th minute of every hour. will take snapshots of every set under pool1 (recursevly)  
- on 55th minute of 23rd hour. replicate them to pool2/auto
	- after backup finished. prune source leaving only s_k=12 snapshots 
	- after prune-src finished. prune destination leaving only d_k=24 snapshots 

### caveats
1. (a few [STDERR] from zfs are normal during first backups, as an unprivileged user can create dataset but not mount)
2. (root operation not necessary, but is needed for pool creation and initial zfs deligation)  
	(look at testing/zfs_test-deligate.sh for minimal zfs permissions needed for unpriviliged user)
3. (remote source or destination require ssh be configured with paswordless/pubkey login (ssh-copy-id or manualy))
4. (if datasets are very big , run initial backups manualy, later incrementals are way faster)(no locking yet)  
	(or schedule a one time run, and then implement the incremental schedule)
5. While simpler uses of the scripts only rely only on a single config file.  
	- Extended control is achieved trough setting zfs user properties on sets
		1. pfix:incl=[c,p,d,e]  sets dataset type container,parent,dataset or exluded
		2. pfix:minws=[bytes] (optional) sets minimal bytes written before snapshot (snap_type 1 option)  
		(can overwrite inherited settings on children back to 0 or another size)
		3. pfix:nsnap:[m,w,d,h]=[0,1] (optional) chooses which snapshots to take (snap_type 3 option)  
		(no need to set if doing all. 0 to disable some, 1 only to overwrite inherited 0 on children)
	- Or multiple executions with different config files
	- And different pfixes (can intermingle multiple configs withing same dataset structure)
6. Multiple config executions can log to the same log files but only if not ran concurrently
	- otherwise you get a mess of a logfile.
	
## restoring (back to source)

- is done with ((ssh user@host) zfs send |(ssh user@host) zfs recv)  
(lots of documentation online for this procedure, and is essential to know when working with zfs) 

- any user set properties originaly being source=local become source=received after any send|recv procedures (forever it seems)
	1. can be set again to get source=local to hide received. but (zfs inherit -S property) can restore back to hidden received.
	2. can be dumped with -x property during send|recv and set again for posterity. to get source=local without a hidden received.
	3. can be ignored, as scripts deals with both local and received (recieved only on destination).

# planned (functionality)

- essential

1. zpool status checks (soon)  
	( checks for scrubing?, resilver and degraded pool status and deal with appropriately)
2. locking to defer operations if currently running.
	1. only problem is big initial backups not finishing, before incrementals start  
	(then do initials manualy)(or schedule first initials friday night and start incrementals on monday)  
	2. if incrementals do not finish, that is a bigger problem  
	(need faster networking and or cpu, use simpler ssh cipher or no cipher ssh patches or HPN-SSH patches)
	
- later

1. zfs clones (not tested yet)  
	(but should? work if transfered with originating dataset@snapshot)
2. zfs volumes (not tested yet)  
	(should work if treated like a data dataset but not tested)
3. zfs encrypted dataset (have not looked in to yet)
4. zfs bookmarks (have not looked in to yet)
5. transport mechanisms besides ssh (future)
6. specifying initial dataset search further down the tree (thinking)
	1. right now list is created right under first level of s_pool or s_pool/s_sets
	- to narrow down further use container sets for now
	- or reorganize pool in to managable sections (ideal)

7. frequent(continuos) snapshotting and replication (pondering)
	1. an edge case.
	- if not planned or done right, can get messy. (which i am trying to avoid)
	- locking and checks etc.. for things to run smoothly. (too many things to go wrong)
	- right now no locks are used, just foresight and correct order of execution.




