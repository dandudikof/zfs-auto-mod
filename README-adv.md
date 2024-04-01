# pfix

<details> <summary> expand this section </summary> <br>

- one of the first things set in config is pfix=auto  

	- sets the property that scripts use to differentiate between own or foreign settings and snapshots  
 
		*(changing pfix on a config and executing again would disregard all previous settings  
		and snapshots and will treat them as foreign, will not prune old pfix, but will backup as foreign)*  
	
	- pfix is also  prepended to each snapshot taken `dataset@auto-t1_2025-05-01_00-20-00_n77`

- from this point on **all** following **(optional)** properties  have to be set with  **same** pfix as config 

- user set zfs properties on datasets
	 1. properties for dataset list creation/sorting  
	 
		auto:incl=[c,p,d] (dataset classification)  
		auto:excl=1 (dataset exclude)

		`zfs set auto:incl=c pool/container`  
		`zfs set auto:incl=p pool/parent`  
		`zfs set auto:incl=d pool/dataset`  
		`zfs set auto:excl=1 pool/excluded`  
		
	2. properties for extended snapshot control  
	
		auto:nsnap=[0,1] *(snap_type=1 option)*  (0 disables snapshots, 1 overrides inherited 0 on children)  
		auto:minws=[bytes] *(snap_type=1 option)*  (0 overrides inherited size on children)  
		auto:nsnap:[m,w,d,h]=[0,1] *(snap_type=2 option)*  (0 disables some snapshots, 1 overrides inherited 0 on children)  
		auto:minws:[m,w,d,h]=[bytes] *(snap_type=2 option)*   (0 overrides inherited size on children)  

		`zfs set auto:nsnap=0 pool/dataset1`  
		`zfs set auto:minws=1000000 pool/dataset2`  
		`zfs set auto:nsnap:h=0 pool/dataset3`   
		`zfs set auto:minws:h=1000000 pool/dataset3`

	3. script (automatically) sets properties on snapshots

		`auto:snum=110` (each snapshot gets a snapshot number) <br>
		`auto:tsnum=101` (last transferred snapshot, for source pruning checks) <br>
		`auto:stype:[1,2]:[m,w,d,h]` (snapshot type, for identification during pruning) <br>
		`auto:sdate:Yn:my:wy:dm:hd` (snapshot date-time, for source snapshot checks)
		
	4. script also (automatically) sets properties on snapshots (that can be used later)  
	
		`zfs-auto-mod:v=1.01` (for future version migrations) <br>
		`zfs-auto-mod:d=Yn:my:dm:hd:mh` (for easy date-time field separate-able values) 
	
- Checking  zfs user properties (listing all current pfix properties)    
 
	`zfs get -t filesystem,volume -s local,received -r all pool1 | grep auto:`
	```
	pool1/type1/container           auto:incl             c                      local
	pool1/type1/excluded            auto:excl             1                      local
	pool1/type1/parent              auto:incl             p                      local
	pool1/type2/container           auto:incl             c                      local
	pool1/type2/dataset1            auto:incl             d                      local
	pool1/type2/dataset2            auto:incl             d                      local
	pool1/type2/dataset2            auto:nsnap:h          0                      local
	pool1/type2/dataset3            auto:incl             d                      local
	pool1/type2/dataset3            auto:nsnap:h          0                      local
	pool1/type2/dataset3            auto:nsnap:d          0                      local
	pool1/type2/parent              auto:incl             p                      local
	```


</details>

# zfs delegation

<details> <summary> expand this section </summary> <br>

- non root users need zfs permissions to work with datasets  

	- source permissions  

		`zfs allow -u myuser create,destroy,send,mount,snapshot,hold,userprop src_pool`  
	
	- destination permissions  
 
		`zfs allow -u myuser create,destroy,receive,mount,mountpoint,userprop,rollback dest_pool`

- further lock-downs possible 
	(in instances where there is little/zero trust between source and destination)  
			
	- permissions delegated further down the dataset tree (to minimal required)  
	- permission thinned to only necessary for operations (to minimal required)  
	
	1. example1. pull backup from remote source that does its own snapshots and pruning  
	user from destination would not need create,destroy,mount,snapshot on source  
	(as he will only be pulling and setting user props on snapshots after completion)  
	(hence he cannot do much damage to source)
	
	2. example2. push backup from local source to remote destination.  
	but without pruning the remote destination and leaving that job for destination to handle.  
	user from source would not need destroy on destination , and no need for rollback unless  
	force pushing a rolled back sets.  
	
	</details>
	
# ssh

<details> <summary> expand this section </summary> <br>

### pubkey

- for remote source or destination ssh needs to be configured with a paswordless pubkey login  
	`ssh-keygen` (only if one does not exist yet!!!) <br>
	`ssh-copy-id user@server` (or copy manually) <br>
	can test with `ssh user@server hostname` ( if returns **only** the expected hostname, everything is aok)

### user != user

- s_user and d_user property in config file is the username to use by scripts on remote side  
(does not have to match the username of user executing the script)

- but current user executing the script must have his pub key copied  
to the remote user ~/.ssh/authorized_keys with ssh-copy-id

	
### ssh options

- s_ssh and d_ssh in config exist for appending ssh and ssh options to source and destination commands.
- or use ~/.ssh/config  host and user sections for more extensive modifications

### multiplexing

- some **remote** operations can be sped up significantly with ssh multiplexing  
	(specifically lots of small procedures like snapshot taking and pruning, also src list creation)

	as each snapshot or prune request requires many remote commands (multiplied by amount of sets),  
	all requiring a new ssh session to be negotiated inside a new tcp session etc...  
	
- ssh multiplexing keeps a single control session open and reuses it for subsequent commands  
[OpenSSH/Cookbook/Multiplexing](https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing)  

	(will not speed up zfs send | zfs recv operations, go to next section)

### faster zfs transfers  

1. use of faster ciphers [Bench-marking SSH](https://www.linkedin.com/pulse/bench-marking-ssh-ciphers-transfer-speed-phil-cryer-eakxc)  (with modern cpu encryption support)
2. High Performance SSH [HPN-SSH](https://github.com/rapier1/hpn-ssh)  (ssh for **super computer** use)
3. try transport=netcat or mbuffer (just implemented, need testing, go to next section)


 </details>


# transport

<details> <summary> expand this section </summary> <br>

- ssh  (standard transfer mechanism, secure, but limited in speed)
-  netcat (recent addition, insecure, fast, no/minimal tuning options)  
-  mbuffer (recent addition, insecure, fastest, some tuning options)  

	*(for netcat and mbuffer, even if destination is local,  still need to set correct d_ip,  
	as to let remote source know where to connect!)*  

</details>

# usage-examples

<details> <summary> expand this section </summary> <br>

execution is (/path_to/script.sh /path_to/config1.cfg) no flags  

- **source** and **destination** are local/remote **agnostic**.  
(controlled with buildup of **composite** source s_srv or destination d_srv commands in config)  
*(leaving s_srv or d_srv unset or blank sets source or destination to local execution mode)*

	1. **source** is what takes initial snapshots and prunes source snapshots (after backups)  
	(backup script replicates all included sets from source to destination)
	2. **destinations** receives sources backups and prunes destination snapshots (after backups)  
	
- Any part of the script (snap/bak/prune[s,d]) can be executed from any location (depending on needs).  
*(provided ssh access and correct zfs permissions have been granted)*
	
- Scheduling can be in any order. as there are checks/locks (for things i could foresee).  
	But makes more sense to run backups after snaps, when there is something new to backup,  
	prunes after backups when source will allow pruning of already transferred snapshots,  
	and destination has something to prune. and logs do not get filled with no action updates!  
	*(also sequential execution, will help ensure logs do not get clobbered)*
 
### 1. local(src) snap/prune and remote(dest) (push) backup/prune 

<details> <summary> expand this section </summary> <br>

- config and execution is on source server  
(script needs to only be installed on source server)  

1. by setting `s_srv=""` to empty string , makes **source**  s_zfs command **local**  
`/sbin/zfs`

3. by setting `d_srv="$d_ssh $d_user@$d_ip"`  , makes **destination** d_zfs command  **remote**  
`ssh user@10.0.0.56 /sbin/zfs`  
	
```
#config1.cfg (minimal settings needed for a local(src) snap/prune and remote(dest) back/prune)

script_dir=~/zfs-auto-mod

source $script_dir/config/shared.cfg		# source shared defaults

pfix="auto"
snap_type=1
set_recurse=1

s_srv=""
s_zfs="$s_srv $zfs"

s_pool="pool1"
s_type=sbp
s_k=12

d_user="user"
d_ip="10.0.0.56"
d_ssh="ssh"

d_srv="$d_ssh $d_user@$d_ip"
d_zfs="$d_srv $zfs"

d_pool="pool2"
d_path="pool2/auto"
d_type=pri
d_k=24

verbose=1
```
### crontab
```
# users or roots crontab on source server
55 * * * * ~/zfs-auto-mod/zfs_auto_snap.sh ~/zfs-auto-mod/config/config1.cfg
59 23 * * * ~/zfs-auto-mod/zfs_auto_bak.sh ~/zfs-auto-mod/config/config1.cfg; ~/zfs-auto-mod/zfs_auto_prune-src.sh ~/zfs-auto-mod/config/config1.cfg; ~/zfs-auto-mod/zfs_auto_prune-dest.sh ~/zfs-auto-mod/config/config1.cfg
```
- on 55th minute of every hour  
	- take **local**(src) snapshots of every set under pool1 (recursively)  
- on 59th minute of 23rd hour  
	- replicate them from **local**(src) to **remote**(dest) pool2/auto
	- after backup finished. prune **local**(src) source leaving only s_k=12 snapshots 
	- after prune source finished. prune **remote**(dest) leaving only d_k=24 snapshots 
	
</details>

### 2. remote(src) snap/prune and remote(dest) (pull-push) backup/prune  

<details> <summary> expand this section </summary> <br>  

- config and execution is now on intermediate server  
(script now needs to only be installed on intermediate  server)  

1. by setting `s_srv="$d_ssh $d_user@$d_ip"`  , makes **source** s_zfs command  **remote**  
	`ssh user@10.0.0.55 /sbin/zfs`      
  
2. by setting `d_srv="$d_ssh $d_user@$d_ip"`  , makes **destination** d_zfs command  **remote**  
	`ssh user@10.0.0.56 /sbin/zfs`      

```  
#config3-inter.cfg (minimal settings needed for a remore(src) snap/prune and remote(dest) back/prune)  
  
script_dir=~/zfs-auto-mod

source $script_dir/config/shared.cfg		# source shared defaults
  
pfix="auto"
snap_type=1
set_recurse=1

s_user="user"
s_ip="10.0.0.55"
s_ssh="ssh"

s_srv="$s_ssh $s_user@$d_ip"
s_zfs="$s_srv $zfs" 
  
s_pool="pool1"
s_type=sbp
s_k=12
  
d_user="user"
d_ip="10.0.0.56"
d_ssh="ssh"
  
d_srv="$d_ssh $d_user@$d_ip"
d_zfs="$d_srv $zfs"
  
d_pool="pool2"
d_path="pool2/auto"
d_type=pri
d_k=24
  
verbose=1
```  
  ### crontab
```  
# users or roots crontab on intermediate server  
55 * * * * ~/zfs-auto-mod/zfs_auto_snap.sh ~/zfs-auto-mod/config/config3-inter.cfg  
59 23 * * * ~/zfs-auto-mod/zfs_auto_bak.sh ~/zfs-auto-mod/config/config3-inter.cfg; ~/zfs-auto-mod/zfs_auto_prune-src.sh ~/zfs-auto-mod/config/config3-inter.cfg; ~/zfs-auto-mod/zfs_auto_prune-dest.sh ~/zfs-auto-mod/config/config3-inter.cfg  
```  

- on 55th minute of every hour. will take **remote** snapshots of every set under pool1 (recursively)   
- on 59th minute of 23rd hour. replicate them to **remote** pool2/auto  
 - after backup finished. prune **remote** source leaving only s_k=12 snapshots   
 - after prune source finished. prune **remote** destination leaving only d_k=24 snapshots

</details>

### 3. local(src) snap/prune and remote(src) (pull) backup and local(dest) prune (split configs) 

<details> <summary> expand this section </summary> <br>  

- now config is split in to 2 parts, and execution is called from source and destination
	1. **local** source does its own snapshots and its own pruning 
	2. **local** destination does (pull) replication from **remote** source and **local** destination pruning  
(script needs to be installed on both source and destination servers)

### source

1. by setting `s_srv=""` to empty string , makes **source**  s_zfs command **local**.
	`/sbin/zfs` 
	
*(sources config does not need any of the destination settings as it will not execute anything on destination)*  
	
```
#config2-src.cfg (minimal settings needed for a local(src) snap/prune)

script_dir=~/zfs-auto-mod

source $script_dir/config/shared.cfg		# source shared defaults

pfix="auto"
snap_type=1
set_type=d
set_recurse=1

s_srv=""
s_zfs="$s_srv $zfs"

s_pool="pool1"
s_type=sbp
s_k=12

verbose=1
```
### crontab
```
# users or roots crontab on source server
55 * * * * ~/zfs-auto-mod/zfs_auto_snap.sh ~/zfs-auto-mod/config/config2-src.cfg
59 3 * * *  ~/zfs-auto-mod/zfs_auto_prune-src.sh ~/zfs-auto-mod/config/config2-src.cfg
```
- on 55th minute of every hour  
	-  take **local**(src) snapshots of every set under pool1 (recursively)  
- on 59th minute of 3rd hour  
	-  prune **local**(src) leaving only s_k=12 snapshots  
*(3rd hour just to give enough time(4hrs) for destination to pull before pruning,  
or pfix:tsnum check will defer pruning of not yet transferred snaps till next iteration)*

### destination

1. by setting `s_srv="$d_ssh $d_user@$d_ip"`  , makes **source** s_zfs command  **remote**  
	`ssh user@10.0.0.55 /sbin/zfs`      
	
1. by setting `d_srv=""` to empty string , makes **destination**  d_zfs command **local**.
	`/sbin/zfs``
	
- destination config now needs both source and  destination settings as it will execute both sides.  
*(but can omit source pruning options as source prunes itself locally)*  
(backup will be from remote(src) to local(dest), and pruning will be on local(dest))
```
#config2-dest.cfg (minimal settings needed for a remote(src) backup and local(dest) prune)

script_dir=~/zfs-auto-mod

source $script_dir/config/shared.cfg		# source shared defaults

pfix="auto"
snap_type=1
set_type=d
set_recurse=1

s_user="user"
s_ip="10.0.0.55"
s_ssh="ssh"

s_srv="$s_ssh $s_user@$d_ip"
s_zfs="$s_srv $zfs"

s_pool="pool1"
s_sets=
s_type=sbp

d_srv=""
d_zfs="$d_srv $zfs"

d_pool="pool2"
d_path="pool2/auto"
d_type=pri
d_k=24

verbose=1
```
### crontab
```
# users or roots crontab on destination server
59 23 * * * ~/zfs-auto-mod/zfs_auto_bak.sh ~/zfs-auto-mod/config/config2-dest.cfg; ~/zfs-auto-mod/zfs_auto_prune-dest.sh ~/zfs-auto-mod/config/config2-dest.cfg
```
- on 59th minute of 23rd hour  
	-  replicate from **remote**(src) to **local**(dest) pool2/auto
	- after backup finished. prune **local**(dest) leaving only d_k=24 snapshots
	
</details>

### 4. local(src) snap/prune and multiple remote(dest)  (push) backup/prune (multiple config files)  

<details> <summary> expand this section </summary> <br>  

- multiple config executions with (different destinations) using a template config and (sharing log files)

### primary

1. by setting `s_srv=""` to empty string , makes **source**  s_zfs command **local**  
`/sbin/zfs`

1. by setting `d_srv="$d_ssh $d_user@$d_ip"`  , makes **destination** d_zfs command  **remote**  
	`ssh user@10.0.0.56 /sbin/zfs`      
	 
```  
#config4-primary.cfg (minimal settings needed for a local(src) snap/prune and remote(dest) back/prune)  
  
script_dir=~/zfs-auto-mod

source $script_dir/config/shared.cfg		# source shared defaults 
  
pfix="auto"  
snap_type=1  
set_type=d  
set_recurse=1  

s_srv=""
s_zfs="$s_srv $zfs" 
  
s_pool="pool1"  
s_type=sbp  
s_k=12  

d_user="user"
d_ip="10.0.0.56"
d_ssh="ssh"

d_srv="$d_ssh $d_user@$d_ip"
d_zfs="$d_srv $zfs" 
  
d_pool="pool2"  
d_path="pool2/auto"  
d_type=pri  
d_k=24  
  
verbose=1  
```  

### secondary

3. by sourcing the previous config we are keeping everything the same and just overriding new destination
(can be just a duplicated primary config with changed options, but this show template type config usage)
 *(and can also override or set any other options that we see fit)*  
 
5. by setting `d_srv="$d_ssh $d_user@$d_ip"`  , makes **destination** d_zfs command  **remote**  
	`ssh user@10.0.0.57 /sbin/zfs`      

6. and changing to dest_type=sec (as not to cause this backup to set pfix:ltsnum which is for a single pri dest only)

```  
#config4-secondary.cfg (minimal settings needed for secondary remote(dest) back/prune)  

script_dir=~/zfs-auto-mod  
  
source $script_dir/config/config4-primary.cfg			# source primary config
  
d_user="user"
d_ip="10.0.0.57"
d_ssh="ssh"

d_srv="$d_ssh $d_user@$d_ip"
d_zfs="$d_srv $zfs" 

d_type=sec

```  
### crontab
```  
# users or roots crontab on source server  
55 * * * * ~/zfs-auto-mod/zfs_auto_snap.sh ~/zfs-auto-mod/config/config4-primary.cfg
59 23 * * * ~/zfs-auto-mod/zfs_auto_bak.sh ~/zfs-auto-mod/config/config4-primary.cfg; ~/zfs-auto-mod/zfs_auto_bak.sh ~/zfs-auto-mod/config/config4-seconday.cfg; ~/zfs-auto-mod/zfs_auto_prune-src.sh ~/zfs-auto-mod/config/config4-primary.cfg; ~/zfs-auto-mod/zfs_auto_prune-dest.sh ~/zfs-auto-mod/config/config4-primary.cfg; ~/zfs-auto-mod/zfs_auto_prune-dest.sh ~/zfs-auto-mod/config/config4-secondary.cfg

# this is where crontabs lack of line splitting forces you to use launcher scripts instead!!!
```  
(sequential execution is essential here, as we are logging to the same log and trying to avoid clobbering)  
*(just an example! if so desired, log files can be separate peer config, overridden after sourcing of previous .cfg)*  

- on 59th minute of every hour  
 
	-  will take **local**(src) snapshots of pool1 (recursively)  

- on 56th minute of 23rd hour  
 
	-  replicate both pri and sec configs from **local**(src) to **remote**(dest) pool2/auto  (sequentially)  

 - after backups finished  
  
	 -  prune primary config **local**(src)
 
 - after source prune finished  
 
	 -  prune both pri and sec configs **remote**(dest) 

</details>
</details>

# manual-interventions

<details> <summary> expand this section </summary> <br>  

 - When things happened that you did not expect or want (and how to deal)  
*(remove (-r) if recursive is not the intention in following commands)*  

1. selecting snapshots by pfix:stype:1  (all type 1 snapshots)
	
	`zfs get -t snapshot -s local,received -H -o name -r auto:stype:1 pool1/type1`
	```
	pool1/type1/container/dataset1@auto-t1_2025-01-11_12-00-00_n22
	pool1/type1/container/dataset1@auto-t1_2025-01-12_00-00-00_n23
	pool1/type1/container/dataset1@auto-t1_2025-01-12_12-00-00_n24
	pool1/type1/dataset1@auto-t1_2025-01-11_12-00-00_n22
	pool1/type1/dataset1@auto-t1_2025-01-12_00-00-00_n23
	pool1/type1/dataset1@auto-t1_2025-01-12_12-00-00_n24
	pool1/type1/dataset1/dataset1@auto-t1_2025-01-11_12-00-00_n22
	pool1/type1/dataset1/dataset1@auto-t1_2025-01-12_00-00-00_n23
	pool1/type1/dataset1/dataset1@auto-t1_2025-01-12_12-00-00_n24
	pool1/type1/parent/dataset1@auto-t1_2025-01-11_12-00-00_n22
	pool1/type1/parent/dataset1@auto-t1_2025-01-12_00-00-00_n23
	pool1/type1/parent/dataset1@auto-t1_2025-01-12_12-00-00_n24
	```
2. selecting snapshots by pfix:stype:2:d and auto:stype:2:h  (all type 2 daily and hourly snapshots)

	`zfs get -t snapshot -s local,received -H -o name -r auto:stype:2:d,auto:stype:2:h pool1/type2`
	```
	pool1/type2/dataset1@auto-t2_2025-01-06_12-00-00_h-n12
	pool1/type2/dataset1@auto-t2_2025-01-07_12-00-00_h-n14
	pool1/type2/dataset1@auto-t2_2025-01-08_12-00-00_h-n16
	pool1/type2/dataset1@auto-t2_2025-01-09_12-00-00_h-n18
	pool1/type2/dataset1@auto-t2_2025-01-10_00-00-00_d-n19
	pool1/type2/dataset1@auto-t2_2025-01-10_12-00-00_h-n20
	pool1/type2/dataset1@auto-t2_2025-01-11_00-00-00_d-n21
	pool1/type2/dataset1@auto-t2_2025-01-11_12-00-00_h-n22
	pool1/type2/dataset1@auto-t2_2025-01-12_12-00-00_d-n24
	pool1/type2/dataset2@auto-t2_2025-01-10_00-00-00_d-n12
	pool1/type2/dataset2@auto-t2_2025-01-11_00-00-00_d-n13
	pool1/type2/dataset2@auto-t2_2025-01-12_12-00-00_d-n15
	```
3. selecting snapshots by auto:snum  (all snapshots with pfix=auto snapshots)  
	 
	`zfs get -t snapshot -s local,received -H -o name -r auto:snum pool1`
	```
	pool1/type1/container/dataset1@auto-t1_2025-01-01_00-00-00
	pool1/type1/container/dataset1@auto-t1_2025-01-01_12-00-00
	pool1/type1/container/dataset1@auto-t1_2025-01-02_00-00-00
	pool1/type1/dataset1@auto-t1_2025-01-01_00-00-00
	pool1/type1/dataset1@auto-t1_2025-01-01_12-00-00
	pool1/type1/dataset1@auto-t1_2025-01-02_00-00-00
	pool1/type1/dataset1/dataset1@auto-t1_2025-01-01_00-00-00
	pool1/type1/dataset1/dataset1@auto-t1_2025-01-01_12-00-00
	pool1/type1/dataset1/dataset1@auto-t1_2025-01-02_00-00-00
	pool1/type1/parent/dataset1@auto-t1_2025-01-01_00-00-00
	pool1/type1/parent/dataset1@auto-t1_2025-01-01_12-00-00
	pool1/type1/parent/dataset1@auto-t1_2025-01-02_00-00-00
	pool1/type2/dataset1@auto-t2_2025-01-01_00-00-00_m-n1
	pool1/type2/dataset1@auto-t2_2025-01-01_12-00-00_w-n2
	pool1/type2/dataset1@auto-t2_2025-01-02_00-00-00_d-n3
	pool1/type2/dataset2@auto-t2_2025-01-01_00-00-00_m-n1
	pool1/type2/dataset2@auto-t2_2025-01-01_12-00-00_w-n2
	pool1/type2/dataset2@auto-t2_2025-01-02_00-00-00_d-n3
	pool1/type2/dataset3@auto-t2_2025-01-01_00-00-00_m-n1
	pool1/type2/dataset3@auto-t2_2025-01-01_12-00-00_w-n2
	```
4.  and do the following with **CAUTION!!!**, using examples of zfs commands above (modify as needed)  
*(and change what what you think needs to be changed, to execute the following commands correctly)*
	`for i in $(zfs get -t snapshot -s local,received -H -o name -r auto:snum pool1/type2); do echo "zfs destroooy $i"; done`

5. **screw this script !!! I am going home** (nuclear option)
	`for i in $(zfs get -t snapshot -s local,received -H -o name -r zfs-auto-mod:v pool1); do echo "zfs destroooy $i"; done`
</details>
