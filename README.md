


# zfs-auto-mod
Bash based, ZFS snapshot replicate and prune scripts.  
local and remote execution, pull or push replication.  

*(with ssh,netcat and mbuffer as transport mechanisms)*

## mission
Support (Open-ZFS) on Linux and FreeBSD.  

Focus on simple, clean, not too convoluted code, without excessive nesting  
and function recursions, for easier maintenance and debugging of the script.  

## notes (beta)
* Even though i have been using it for more then a few years, consider it (**beta**).  
*(until there is more testing and feedback to say otherwise)*  

	* Tested on devuan/debian/freebsd so far (but assume debian/freebsd based (others?) should work).  
	* Besides bash and crontab, GNU coreutils versions of cat,tac,tail,head,printf,date,grep,sed,ps,tr  
	and for remote (ssh,ping,etherwake or wakeonlan, also netcat and mbuffer) are used is the scripts.  

	*(until i see or hear some feedback or any outside interest in this repository,  
	 i will reserve the right to rebase and force push, down to last stable release tag)*

# scripts (descriptions)
*each script can execute commands locally or remotely for (src or dest or both)*

### zfs_auto_snap.sh (2 types of snapshots)
will snapshot all source sets classified as (dataset) based on snap_type  

1. (**snap_type 1**) takes snapshots whenever called (run up to hourly)  
	```
	pool1/type1/dataset1@auto-t1_2025-05-01_00-20-00
	pool1/type1/dataset1@auto-t1_2025-05-01_01-20-00
	pool1/type1/dataset1@auto-t1_2025-05-01_02-20-00
	```
	with **optional** (recursive) nsnap (need-snap) option for disabling snapshots (0 disables)  
	*(use when someone or something else is handling snapshots on this set, but still doing backup)*  
	`zfs set pfix:nsnap=[0,1] pool/dataset`   
	(change pfix to match config and pick 0 or 1) (omit [ ])  
		
	with **optional** (recursive) minws option for minimal written size before snapshot is taken.  
	*(when written size reaches set value take a snapshot)*  
	`zfs set pfix:minws=[bytes] pool/dataset`  
	(change pfix to match config and bytes) (omit [ ])  

2. (**snap_type 2**) takes monthly weekly daily hourly snapshots (run up to hourly)  
	
	- first snapshot of the month takes a monthly snapshot.  
	- first snapshot of the week takes a weekly snapshot.  
	- first snapshot of the day takes a daily snapshot.  
	- all others snapshots taken are hourly snapshots.  
	```
	pool1/type2/dataset1@auto-t2_2025-05-01_00-20-00_m
	pool1/type2/dataset1@auto-t2_2025-05-01_01-20-00_w
	pool1/type2/dataset1@auto-t2_2025-05-01_02-20-00_d
	pool1/type2/dataset1@auto-t2_2025-05-01_03-20-00_h
	```
	 with **optional** (recursive) nsnap (need-snap) option for finer grained snapshot control (0 disables)  
	 *(of whether not to take (monthly weekly daily hourly) snapshots)*  
		`zfs set pfix:nsnap:[m,w,d,h]=[0,1] pool/dataset`  
		(change pfix to match config and pick one of mwdh and 0 or 1) (omit [ ])  
		 
	with **optional** (recursive) minws option for minimal written size before snapshot is taken.  
	*(when written size reaches set value for (monthly weekly daily hourly) take a snapshot)*  
		`zfs set pfix:minws:[m,w,d,h]=[bytes] pool/dataset`  
		(change pfix to match config and pick one of mwdh, and bytes) (omit [ ])  
	
3. (**parent**) will also snapshot dataset@$pfix-parent for s_pool and other parent datasets (once)  
	*(parent snapshot can be deleted on src and dest to force a resend of new zfs set properties).*

### zfs_auto_bak.sh 
will replicate datasets from source to destination.

1. sorts backup list in correct order (backup children after parents)
2. creates destination path on dest (d_path, maybe hostname of src)
3. creates (**container**) sets on dest (sets for organization only)
4. replicates (**parent**) sets to dest (sets for organization and zfs properties transfer)
5. replicates (**dataset**) sets to dest (data sets with script created and all other snapshots)

*(avoid storing data in s_pool and other parent datasets, as they force push only on initial replication)* 

- with **option** for secondary backup destination(s)  
 
1. duplicate config with d_type=sec and new destination settings, and run backup/prune-dest again  
(sec destinations does not set pfix:tsnum, as source prune only checks against a single primary)  
(pfix:tsnum stops source from pruning snapshots not yet transferred to primary destination)  
*(execute secondary after primary but before source prunes, so that same snapshots transfer to secondary(s))*  
(**new config file**)

2. or make original primary destination a source for a new primary destination and run backup and prune-dest  
(now executing backup/prune-dest scripts on a new source server if pushing or new destination if pulling)  
(**new config file on new server**)

### zfs_auto_prune-[src,dest].sh

will prune source or destination snapshots (based on pfix, snap_type and [s,d]_k[m,w,d,h] options)   
*(manually created or any other snapshots which were not created by script/config/pfix remain untouched)*

- prune is based on amount of snapshots to keep (not dates/times/intervals). keeping the code very simple.

- with **option** for pruning source with or without backup checks  
	1.  s_type=sp just snapshot and prune source (without backup)  
	(will prune as specified by config without pfix:tsnum checks)  

	2. s_type=sbp to snapshot, backup, prune-src and prune-dest (backup enabled)  
	(with pfix:tsnum checks, will avoid pruning src snapshots not yet transferred to primary destination)  
	*(when dest server is down/unavail but snapshots grew past the s_k for prunning, but not yet transfered etc..)*


# functions (descriptions)

<details> <summary> expand this section </summary> <br>  

(used in each script)

### fnc_compatibility.sh
checks for FreeBSD and loads compatibility shim functions  
*(for missing tac, and missing extra head/tail options in non GNUs versions)*

### fnc_lock-check.sh
locking on a peer script peer config file basis  
1. checks for and creates locking directories
3. checks if it may be a stale lock or stolen pid (clears them)
4. checks for current script and config lock files (if exist send an ERROR to the log and stop script)
5. creates locks files if none exist (continue script)
6. deletes locks files when done

(can run same script with different configs or other scripts with same config at same time)  
(ie - will stop another backup on same config if old one has not finished, but can still snap/prune)  

### fnc_remote-check.sh
ping checks source and destination if set as remote. and sends a wake_cmd if configured
1. just to check if remote server is reachable before starting script 
2. wake up remote server if needed , wait for server to come up and continue script
3. if remote source or destination is unreachable (send ERROR to log and stop script)

### fnc_pool-check.sh
checks the health status of the s_pool and d_pool
1. if pool is ONLINE (continue script)
2. if DEGRADED,SUSPENDED,UNAVAIL etc.. (send an ERROR to the log and stop script)

### fnc_sort-list.sh 
- Builds arrays of sets based on supplied s_pool or s_pool/[s_sets] if set, that scripts act on.

	(s_pool always treated as a parent. not for data)  
	*(if s_sets is not set then whole s_pool is searched)*  

- will treat everything under s_pool or s_pool/[s_sets] as datasets.  
		1. unless overridden by by pfix:incl=[c,p] as another type or pfix:excl=1 as excluded.  
		2. or stopped by set_recurse=0 option, then only sets with pfix:incl=[c,p,d] are included
	
	(s_sets themselves are set by set_type option and can be overridden by pfix:incl zfs property)

- **optional**  
	(no need to set unless that functionality is needed or using set_recurse=0)  
	*(set_recurse=0 will not descend in to s_sets unless pfix:incl is set on children)*
	
	zfs set pfix:incl=[c,p,d] pool/dataset (change pfix to match config and pick one c,p,d) (omit [ ])  
	zfs set pfix:excl=1 pool/dataset (change pfix to match config)  
	
	`zfs set pfix:incl=c pool/container`  
	`zfs set pfix:incl=p pool/parent`  
	`zfs set pfix:incl=d pool/dataset`  
	`zfs set pfix:excl=1 pool/dataset`  

	1. (**container**) incl d_path do not get transferred during backups but simply recreated on dest (as path objects)
	2. (**parent**) gets a set@pfix-parent snapshot and is transferred once on first backup (to transfer zfs properties)
	3. (**dataset**) gets a snapshots based on snap_type and is always transferred and pruned
	4. (**excluded**) excludes the set itself and all children from all operations (snap,back,prune)

	basic debug is enabled with verblist=1 *(will log a list of of all sets and classifications they received)*

### fnc_logging.sh
logging functionality of the script *(does not depend on system logging)*

- assigns logging channels to functions or files.
- chooses what to log based on verbosity of config
- some editing and cleaning of logging data 
(like trimming/formatting zfs send and zfs recv output)

*(rotations of log files needs to be setup separately with logrotate)*  

</details>

# install (no packaging yet)
git clone inside your $HOME directory  
`git clone https://github.com/dandudikof/zfs-auto-mod.git`  
- Linux and FreeBSD
1. If cloned somewhere else, edit $script_dir to correct location in /config/*.cfg files  
2. (non root) Needs $log_dir created (and be writable by user/group )  
3. (non root) Needs $lock_dir created (and be writable by user/group )  
4. (non root) Needs zfs allow to delegate correct permissions to user for access  
5. (remote) source or destination require ssh  with paswordless/pubkey login.  
6. (mbuffer) install if using it as transport mechanism	
- FreeBSD  
7. Needs bash installed `pkg install bash`  
8. Needs GNU coreutils installed `pkg install coreutils`  
9. Needs a softlink of /bin/bash to /usr/local/bin/bash `ln -s /usr/local/bin/bash /bin/bash`  
	(or change shebangs in zfs_auto_*.sh files to #!/usr/bin/env bash)  

# usage  (examples)

*execution is a simple (/path_to/script.sh /path_to/simple.cfg) no flags*  

### 1. simple local snapshot,prune 

```
#simple1.cfg (minimal settings needed for a local snap/prune)

script_dir=~/zfs-auto-mod

source $script_dir/config/shared.cfg		# source shared defaults

pfix="auto"
snap_type=1

s_zfs="$zfs"
s_pool="pool1"
s_type=sp
s_k=12

verbose=1
```

```
# users or roots crontab
55 * * * * ~/zfs-auto-mod/zfs_auto_snap.sh ~/zfs-auto-mod/config/simple1.cfg
56 23 * * * ~/zfs-auto-mod/zfs_auto_prune-src.sh ~/zfs-auto-mod/config/simple1.cfg
```
- on 55th minute of every hour. take snapshots of every set under pool1 (recursively)  
- on 56th minute of 23rd hour.  prune source leaving only s_k=12 snapshots 
	
### 2. simple local snapshot,backup,prune 
 
```
#simple2.cfg (minimal settings needed for a local snap/back/prune)

script_dir=~/zfs-auto-mod

source $script_dir/config/shared.cfg		# source shared defaults

pfix="auto"
snap_type=1

s_zfs="$zfs"
s_pool="pool1"
s_type=sbp
s_k=12

d_zfs="$zfs"
d_pool="pool2"
d_path="pool2/auto"
d_type=pri
d_k=24

verbose=1
```

```
# users or roots crontab
55 * * * * ~/zfs-auto-mod/zfs_auto_snap.sh ~/zfs-auto-mod/config/simple2.cfg
56 23 * * * ~/zfs-auto-mod/zfs_auto_bak.sh ~/zfs-auto-mod/config/simple2.cfg; ~/zfs-auto-mod/zfs_auto_prune-src.sh ~/zfs-auto-mod/config/simple2.cfg; ~/zfs-auto-mod/zfs_auto_prune-dest.sh ~/zfs-auto-mod/config/simple2.cfg
```
- on 55th minute of every hour. take snapshots of every set under pool1 (recursively)  
- on 56th minute of 23rd hour. replicate them to pool2/auto
	- after backup finished. prune source leaving only s_k=12 snapshots 
	- after prune source finished. prune destination leaving only d_k=24 snapshots  
	
## restoring (back to source)
is done with ((ssh user@host) zfs send |(ssh user@host) zfs recv)  
*(lots of documentation online for this procedure)* 

### advanced usage notes continues in [README-adv.md](README-adv.md)
### extra info for testing (or a quick intro to the script) in [testing/](testing/)

# caveats

<details> <summary> expand this section </summary> <br> 

1. a few [STDERR] from zfs are normal during first backups  
(as an non root user can create datasets but not mount)  
(and errors about clone set send and encryption property even if encryption not used, zfs bug reported)  
2. root operation not necessary, but is needed for pool creation and initial zfs delegation  
(look at  [zfs delegation](https://github.com/dandudikof/zfs-auto-mod/blob/master/README-adv.md#zfs-delegation) section of README-adv.md)
3. Remote source or destination require ssh with paswordless/pubkey login,  
configure with (ssh-copy-id user@server) or manually  
4. Multiple config executions can log to the same log files  
	(but only if **not** ran **concurrently**, as not to clobber the log)  
	(and single config needs **not** to run scripts **concurrently** also)
5. While simpler uses of the scripts rely only on a single config file.  
	- Extended (**optional**) control is achieved trough setting zfs user properties on sets  
	*(all recursive options are over-ride-able on children, except for pfix:excl)*
		1. pfix:incl=[c,p,d] sets dataset classification type container, parent or dataset
		2. pfix:excl=[1] (recursive) sets dataset and all children as exluded from all operations
		3. pfix:nsnap=[0,1] (recursive) chooses if snapshots are needed (snap_type 1 option)  
			*(when someone or something else is handling snapshots on set. otherwise use container sets)*
		5. pfix:minws=[bytes] (recursive) sets minimal bytes written before snapshot (snap_type 1 option)    
			*(can override inherited settings on children back to 0 or another size)*
		6. pfix:nsnap:[m,w,d,h]=[0,1] (recursive) chooses which snapshots are needed (snap_type 2 option)  
			*(no need to set if doing all. 0 to disable some, 1 only to overwrite inherited 0 on children)*
		7. pfix:minws:[m,w,d,h]=[bytes] (recursive) chooses when snapshots is taken (snap_type 2 option)  
			*(can override inherited settings on children back to 0 or another size)*
	- Or **multiple** executions with different **config files** and different s_sets
	- And or **different pfixes** (can intermingle multiple configs within same dataset structure)
6. Destination pruning depends on source being available (server online) as the set list is created based on  
	sources config, sources zfs listing and and sources zfs user set properties (prune dest after backups)
7. Script uses international date format year/month/day internally  
	(but snapshot names and logging headers can be changed with $DATE and $TIME in shared.cfg)
8. System date/time should be correct at all times (but will **not cause** any catastrophic failures)  
	(snapshot will not be taken only if current date/time snapshot exists. backups should not be affected.  
	and prune is based on amount of specific snapshots to keep not dates/times, so no problems here)  
	(ntpdate on boot and periodically wont hurt)  
9. Snap script will not take anything more frequent then hourly at the moment.
10. Sort list is recursed from first level of s_pool or s_pool/[s_sets]  
	- reorganize pool in to manageable sections (ideal)  
	- to narrow down further use container set (will create missing higher levels)
	-  or use exclude sets to filter out unwanted sets
11. if using transport=netcat or mbuffer local destination still needs to set correct d_ip 
12. If you are using spaces/tabs in pool or set names (rename_them-now)

</details>

# planned (functionality)

0. added netcat and mbuffer  
1. packaging (tarball with make install)? and/or (deb)?
2. zfs bookmarks
3. zfs encrypted dataset
4. frequent(continuous) snapshotting and replication (can get messy)  
	



