#!/bin/bash



[ -z $1 ] && { echo "[ERROR] $(basename $0) NO config file provided" 1>&2; exit 1; }
source $1 || { echo "[ERROR] $(basename $0) could NOT load config file" 1>&2; exit 1; }


printf "\n\n" >> $log_file6			# forward to send long
echo "[$DATE] [$TIME] =============== BACKUP =============== $1" >> $log_file6

printf "\n" >> $log_file3
echo '================================================================================================' >> $log_file3
echo "[$DATE] [$TIME] --------------- BACKUP --------------- $1" >> $log_file3
echo '================================================================================================' >> $log_file3


source $script_dir/fnc_lock-check.sh || { echo '[ERROR] NOT loaded (fnc_lock-check.sh) ' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_remote-check.sh || { echo '[ERROR] NOT loaded (fnc_remote-check.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_pool-check.sh || { echo '[ERROR] NOT loaded (fnc_pool-check.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_sort-list.sh || { echo '[ERROR] NOT loaded (fnc_sort-list.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_logging.sh || { echo '[ERROR] NOT loaded (fnc_logging.sh)' >> $log_file3; fnc_err=1; }
[ "$fnc_err" = 1 ] && { echo "[ERROR] NOT running ($(basename $0)) script, missing functions" >> $log_file3; exit 1; }


do_everything() {
#printf "\n==================================== DO_EVERYTHING ======================================\n\n"

				do_lock_check $1
				do_remote_check1
				do_pool_check1
				do_sort_list"$sort_type" #>/dev/null 3>&1
				do_backup_sort
				
				do_lock_clear $1


}



do_backup_sort() {
#printf "\n--------------------------------------( do_backup_sort )----------------------------------------\n" 1>&4
		# walk the include list in order and call apropriate function

[ "$d_path" != "$d_pool" ] && do_backup_container "$d_path"

for i in "${include_array[@]}" ;do

	case "${include_Array[$i]}" in
	
		c)
			do_backup_container "$i" ;;

		p)
			do_backup_parent "$i" ;;

		d)
			do_backup_head "$i"
			do_backup_incr "$i" ;;

		*)
			continue ;;

	esac

done

for i in "${clone_array[@]}" ;do

	do_backup_head "$i"
	do_backup_incr "$i"

done

}



do_backup_container() {
printf "\n--------------------------------------( do_backup_container )-----------------------------------\n" 1>&4
		# checks for and creates d_path and container sets

local src_set=$1
local dest_set=${dest_Array[$1]}

[ "$src_set" = "$d_path" ] && dest_set=$d_path # do not append src_set if src_set is d_path

	#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
	echo "[DEBUG] src_set = ($src_set)" 1>&5
	echo "[DEBUG] dest_set = ($dest_set)" 1>&5
	#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

if $d_zfs list -H -o name $dest_set > /dev/null 2>&1 ;then

	echo "[info2] dest set $dest_set exists" 1>&4

elif ! $d_zfs list -H -o name ${dest_set%/*} > /dev/null 2>&1 ;then

	echo "[ERROR] dest ../ set ${dest_set%/*} does NOT exists" 1>&3
	echo "[ERROR] can NOT create dest set $dest_set" 1>&3

else

	echo "[info2] dest set $dest_set does NOT exist" 1>&4
	echo "[info1] zfs create $dest_set" 1>&3

	local zfs_cmd="$d_zfs create -o mountpoint=none $dest_set"
	echo "[ZFS_CMD] ($zfs_cmd)" 1>&5
	$zfs_cmd

fi

}



do_backup_parent() {
printf "\n--------------------------------------( do_backup_parent )--------------------------------------\n" 1>&4
printf "\n--------------------------------------( do_backup_parent )--------------------------------------\n" 1>&7
		# checks for and replicates parent sets


local src_set="$1"
local dest_set=${dest_Array[$1]}

	#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
	echo "[DEBUG] src_set = ($src_set)" 1>&5
	echo "[DEBUG] dest_set = ($dest_set)" 1>&5
	#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

if $d_zfs list -t snapshot -H -o name $dest_set@$pfix-parent > /dev/null 2>&1 ;then
	
	echo "[info2] dest parent snapshot $dest_set@$pfix-parent exists" 1>&4

elif ! $s_zfs list -t snapshot -H -o name $src_set@$pfix-parent > /dev/null 2>&1 ;then

	echo "[ERROR] src parent snapshot $src_set@$pfix-parent does NOT exist" 1>&3
	echo "[ERROR] can NOT do parent send for $src_set@$pfix-parent" 1>&3

elif ! $d_zfs list -H -o name ${dest_set%/*} > /dev/null 2>&1 ;then

	echo "[ERROR] dest ../ set ${dest_set%/*} does NOT exists" 1>&3
	echo "[ERROR] can NOT do parent send for $src_set@$pfix-parent" 1>&3

else

	echo "[info2] dest parent snapshot $dest_set@$pfix-parent does NOT exist" 1>&4	
	echo "[info1] zfs send $src_set@$pfix-parent" 1>&3

	local zfs_send_cmd="$s_zfs send -pv $src_set@$pfix-parent"
	local zfs_recv_cmd="$d_zfs recv -Fuv $dest_set"

	echo "[ZFS_SEND] ($zfs_send_cmd)" 1>&5
	echo "[ZFS_RECV] ($zfs_recv_cmd)" 1>&5

	echo "------------------------------------------------------------------------------------------------" 1>&9
	 $zfs_send_cmd 2>&6 | $zfs_recv_cmd 1>&8 
	local ret=( "${PIPESTATUS[@]}" )
	sleep 0.1	# to sync logging in this spot, or it jumps order
	echo "------------------------------------------------------------------------------------------------" 1>&9

	if [ "${ret[0]}" != 0 ] || [ "${ret[1]}" != 0 ] ;then

		echo "[DEBUG] zfs send pipeline returns are (${ret[@]})" 1>&5
		echo "[ERROR] zfs send/recv fail for $src_set " 1>&3

	fi

fi

}



do_backup_head() {
printf "\n--------------------------------------( do_backup_head )----------------------------------------\n" 1>&4
printf "\n--------------------------------------( do_backup_head )----------------------------------------\n" 1>&7
		# checks for and replicates head snaps

local src_set="$1"
local dest_set=${dest_Array[$1]}

	#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
	echo "[DEBUG] src_set = ($src_set)" 1>&5
	echo "[DEBUG] dest_set = ($dest_set)" 1>&5
	#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

if $d_zfs list -H -o name $dest_set > /dev/null 2>&1 ; then

	 echo "[info2] dest set $dest_set exist" 1>&4

elif ! $d_zfs list -H -o name ${dest_set%/*} > /dev/null 2>&1 ;then

	echo "[ERROR] dest ../ set ${dest_set%/*} does NOT exists" 1>&3
	echo "[ERROR] can NOT do head send for $src_set" 1>&3

else

	echo "[info2] dest set $dest_set does NOT exist" 1>&4
	
	local head_snap="$($s_zfs list -t snapshot -H -o name $src_set | head -1)"
	local head_snap_num="$($s_zfs get -t snapshot -s local,received -H -o value $pfix:snum $head_snap)"
	local orig_snap="${clone_Array["${src_set:-null}"]}"
	local orig_set="${clone_Array["${src_set:-null}"]%@*}"
	local orig_incl="${include_Array["${orig_set:-null}"]}"

		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] head_snap = ($head_snap)" 1>&5
		echo "[DEBUG] head_snap_num = ($head_snap_num)" 1>&5
		echo "[DEBUG] orig_snap = ($orig_snap)" 1>&5
		echo "[DEBUG] orig_set = ($orig_set)" 1>&5
		echo "[DEBUG] orig_incl = ($orig_incl)" 1>&5
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if [ -z "$head_snap" ] ;then

		echo "[ERROR] head snap NOT found for $src_set" 1>&3
		echo "[ERROR] can NOT do head send for $src_set" 1>&3
		return 1

	elif [ -n "$orig_snap" ] && ! [[ "$orig_incl" = d || "$orig_incl" = cl ]] ;then

		echo "[WARNING] > origin set ($orig_set) is NOT on the dataset include list" 1>&3
		echo "[WARNING] >> clone set ($src_set) will be replicated, but NOT as a clone on dest" 1>&3
		echo "[WARNING] >>> to FIX, add origin set to include AND remove/rename clone set on dest to resend" 1>&3

	fi

	if [ -n "$orig_snap" ] && [[ "$orig_incl" = d || "$orig_incl" = cl ]] ;then

		echo "[DEBUG] ($src_set) is a clone, and origin is ($orig_snap)" 1>&5
		echo "[info1] zfs send $orig_snap" 1>&3
		echo "[info1] to ----> $head_snap" 1>&3
		local zfs_send_cmd="$s_zfs send -pv -i $orig_snap $head_snap"
		local zfs_recv_cmd="$d_zfs recv -uv $dest_set"

	else

		echo "[DEBUG] ($src_set) is not a clone, or origin is not on include list" 1>&5
		echo "[info1] zfs send $head_snap" 1>&3
		local zfs_send_cmd="$s_zfs send -pv $head_snap"
		local zfs_recv_cmd="$d_zfs recv -uv $dest_set"

	fi
	
	echo "[ZFS_SEND] ($zfs_send_cmd)" 1>&5
	echo "[ZFS_RECV] ($zfs_recv_cmd)" 1>&5

	echo "------------------------------------------------------------------------------------------------" 1>&9
	$zfs_send_cmd 2>&6 | $zfs_recv_cmd 1>&8 
	local ret=( "${PIPESTATUS[@]}" )
	sleep 0.1	# to sync logging in this spot, or it jumps order
	echo "------------------------------------------------------------------------------------------------" 1>&9

	if [ "${ret[0]}" != 0 ] || [ "${ret[1]}" != 0 ] ;then

		echo "[DEBUG] zfs send pipeline returns are (${ret[@]})" 1>&5
		echo "[ERROR] zfs send/recv fail for $src_set " 1>&3

	elif [ "$d_type" = "pri" ] && [ -n "$head_snap_num" ] ;then

		local zfs_cmd="$s_zfs set $pfix:tsnum=$head_snap_num $head_snap"
		echo "[ZFS_CMD] ($zfs_cmd)" 1>&5
		$zfs_cmd

	fi

fi

}



do_match_snap(){
#printf "\n--------------------------------------( do_match_snap )-----------------------------------------\n" 1>&4
		# find last matching src and dest snapshots for incr send 

local src_set="$1"
local dest_set=${dest_Array[$1]}

for src_snap in $($s_zfs list -t snapshot -H -o name $src_set | tac ) ;do

		local snap="${src_snap#*@}"

	if $d_zfs list -t snapshot -H -o name $dest_set@$snap > /dev/null 2>&1 ; then

		local s_guid="$($s_zfs get -t snapshot -H -o value guid $src_snap)"
		local d_guid="$($d_zfs get -t snapshot -H -o value guid $dest_set@$snap)"

		if [ "$s_guid" = "$d_guid" ] ; then

			echo "$src_snap"
			return

		fi

	fi

done

}



do_backup_incr() {
printf "\n--------------------------------------( do_backup_incr )----------------------------------------\n" 1>&4
printf "\n--------------------------------------( do_backup_incr )----------------------------------------\n" 1>&7
		# incremental send from last matching dest snap to last source snap

local src_set="$1"
local dest_set=${dest_Array[$1]}

	#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
	echo "[DEBUG] src_set = ($src_set)" 1>&5
	echo "[DEBUG] dest_set = ($dest_set)" 1>&5
	#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

if ! $d_zfs list -H -o name $dest_set > /dev/null 2>&1 ; then

	echo "[ERROR] dest set $dest_set does NOT exist" 1>&3
	echo "[ERROR] can NOT do incr send for $src_set" 1>&3

else

	echo "[info2] dest set $dest_set exist" 1>&4

	local match_snap="$(do_match_snap $src_set)"
	local last_src_snap="$($s_zfs list -t snapshot -H -o name $src_set | tail -n 1)"
	local last_dest_snap="$($d_zfs list -t snapshot -H -o name $dest_set | tail -n 1)"
	local last_auto_snap="$($s_zfs get -t snapshot -s local,received -H -o name $pfix:snum $src_set | tail -n 1)"
	local last_auto_snap_num="$($s_zfs get -t snapshot -s local,received -H -o value $pfix:snum $src_set | tail -n 1)"
	local last_trans_snap="$($s_zfs get -t snapshot -s local,received -H -o name $pfix:tsnum $src_set | tail -n 1)"

		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] match_snap = $match_snap" 1>&5
		echo "[DEBUG] last_src_snap = $last_src_snap" 1>&5
		echo "[DEBUG] last_dest_snap = $last_dest_snap" 1>&5
		echo "[DEBUG] last_auto_snap = $last_auto_snap" 1>&5
		echo "[DEBUG] last_auto_snap_num = $last_auto_snap_num" 1>&5
		echo "[DEBUG] last_trans_snap = $last_trans_snap" 1>&5
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if [ -z "$match_snap" ] ;then

		echo "[ERROR] match_snap NOT found for $src_set" 1>&3
		echo "[ERROR] can NOT do incr send for $src_set" 1>&3
		return 1
		
	elif [ "${match_snap#*@}" != "${last_dest_snap#*@}" ] && [ "$d_force" != 1 ];then
	
		echo "[ERROR] match_snap $match_snap is NOT the last dest snapshot" 1>&3
		echo "[ERROR] rollback dest to $dest_set@${match_snap#*@} OR enable force push" 1>&3
		return 1

	elif [ "$match_snap" = "$last_src_snap" ] ;then

		echo "[info2] match_snap = last src snapshot $last_src_snap "	1>&4
		echo "[info2] NO need to send $last_src_snap"	1>&4
		return 0

	fi

	echo "[info1] zfs send $match_snap" 1>&3
	echo "[info1] to ----> $last_src_snap" 1>&3

	[ "$d_force" = 1 ] && local F=F 

	local zfs_send_cmd="$s_zfs send -pv -I $match_snap $last_src_snap"
	local zfs_recv_cmd="$d_zfs recv -${F}uv -x $pfix:tsnum $dest_set"

	echo "[ZFS_SEND] ($zfs_send_cmd)" 1>&5
	echo "[ZFS_RECV] ($zfs_recv_cmd)" 1>&5

	echo "------------------------------------------------------------------------------------------------" 1>&9
	 $zfs_send_cmd 2>&6 | $zfs_recv_cmd 1>&8 
	local ret=( "${PIPESTATUS[@]}" )
	sleep 0.1	# to sync logging in this spot, or it jumps order
	echo "------------------------------------------------------------------------------------------------" 1>&9

	if [ "${ret[0]}" != 0 ] || [ "${ret[1]}" != 0 ]  ;then

		echo "[DEBUG] zfs send pipeline returns are (${ret[@]})" 1>&5
		echo "[ERROR] zfs send/recv fail for $src_set " 1>&3

	elif [ "$d_type" = pri ] && [ -n "$last_auto_snap_num" ] ;then

		local zfs_cmd="$s_zfs set $pfix:tsnum=$last_auto_snap_num $last_auto_snap"
		echo "[ZFS_CMD] ($zfs_cmd)" 1>&5
		$zfs_cmd

	fi

fi

}



do_everything



exit



