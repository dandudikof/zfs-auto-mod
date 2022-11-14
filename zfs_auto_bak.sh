#!/bin/bash



[ -z $1 ] && { echo "[ERROR] $(basename $0) NO config file provided" 1>&2; exit 1; }
source $1 || { echo "[ERROR] $(basename $0) could NOT load config file" 1>&2; exit 1; }


printf "\n\n" >> $log_file6			# forward to send long
echo "[$DATE] [$TIME] ================ BACKUP ================ $1" >> $log_file6

printf "\n" >> $log_file3
echo '================================================================================================' >> $log_file3
echo "[$DATE] [$TIME] ---------------- BACKUP ---------------- $1" >> $log_file3
echo '================================================================================================' >> $log_file3


source $script_dir/fnc_lock-check.sh || { echo '[ERROR] NOT loaded (fnc_lock-check.sh) ' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_pool-check.sh || { echo '[ERROR] NOT loaded (fnc_pool-check.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_remote-check.sh || { echo '[ERROR] NOT loaded (fnc_remote-check.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_sort-list.sh || { echo '[ERROR] NOT loaded (fnc_sort-list.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_logging.sh || { echo '[ERROR] NOT loaded (fnc_logging.sh)' >> $log_file3; fnc_err=1; }
[ "$fnc_err" = 1 ] && { echo "[ERROR] NOT running ($(basename $0)) script, missing functions" >> $log_file3; exit 1; }


do_everything() {
#printf "\n==================================== DO_EVERYTHING ======================================\n\n"

				do_lock_check
				do_pool_check1
				do_remote_check1
				do_sort_list"$sort_type" #>/dev/null 3>&1
				do_backup_sort
				
				do_lock_clear


}



do_backup_sort() {
#printf "\n---------------------------------- do_backup_sort --------------------------------------\n" 1>&4
		# walk the include list in order and call apropriate function

[ "$d_path" != "$d_pool" ] && do_backup_container "$d_path"

for i in "${include_i_array[@]}" ;do

	case "${include_a_array[$i]}" in
	
		c)
			do_backup_container "$i" ;;

		p)
			do_backup_parent "$i" ;;

		d)
			do_backup_dataset "$i" ;;

		e)
			continue ;;

		*)
			continue ;;

	esac

done

}



do_backup_container() {
printf "\n---------------------------------- do_backup_container ----------------------------------\n" 1>&4
		# checks for and creates d_path and container sets

local src_set=$1
local dest_set=${dest_a_array[$1]}

[ "$src_set" = "$d_path" ] && dest_set=$d_path # do not append src_set if src_set is d_path

	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
	echo "[DEBUG] src_set = ($src_set)" 1>&5
	echo "[DEBUG] dest_set = ($dest_set)" 1>&5
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

$d_zfs list -H -o name $dest_set > /dev/null 2>&1
if [ $? = 0 ] ;then

	echo "[INFO2] dest_set $dest_set exists" 1>&4

else

	echo "[INFO2] dest_set $dest_set does NOT exist" 1>&4
	echo "[INFO1] zfs create $dest_set" 1>&3
	$d_zfs create -p -o mountpoint=none $dest_set

fi

}



do_backup_parent() {
printf "\n---------------------------------- do_backup_parent --------------------------------\n" 1>&4
		# checks for and replicates parent sets


local src_set="$1"
local dest_set=${dest_a_array[$1]}

	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
	echo "[DEBUG] src_set = ($src_set)" 1>&5
	echo "[DEBUG] dest_set = ($dest_set)" 1>&5
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

$d_zfs list -H -o name $dest_set > /dev/null 2>&1
if [ $? = 0 ] ;then

	echo "[INFO2] dest set $dest_set exists" 1>&4

else
	printf "\n------------------------------------ ( parent send ) ----------------------------------\n" 1>&4
	printf "\n------------------------------------ ( parent send ) ----------------------------------\n" 1>&7

	echo "[INFO2] parent set $dest_set does NOT exist" 1>&4
	echo "[INFO1] zfs send $src_set@$pfix-parent" 1>&3

	echo "------------------------------------------------------------------------------------" 1>&9
	$s_zfs send -pv $src_set@$pfix-parent 2>&6 | $d_zfs recv -Fuv $dest_set 1>&8
	local ret=( "${PIPESTATUS[@]}" )
	sleep 0.1	# to sync logging in this spot, or it jumps order
	echo "------------------------------------------------------------------------------------" 1>&9


	if [ "${ret[0]}" != 0 ] || [ "${ret[1]}" != 0 ] ;then

		echo "[DEBUG] zfs send pipeline returns are (${ret[@]})" 1>&5

		echo "**************************************************************************************"  1>&3
		echo "[ERROR] zfs send/recv fail for $src_set " 1>&3
		echo "**************************************************************************************"  1>&3

	fi

fi

}



do_backup_dataset() {
printf "\n---------------------------------- do_backup_dataset ---------------------------------\n" 1>&4
		# checks for and replicates datasets, first sending head snapshots then incremental

########## head snapshot send


local src_set="$1"
local dest_set=${dest_a_array[$1]}

	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
	echo "[DEBUG] src_set = ($src_set)" 1>&5
	echo "[DEBUG] dest_set = ($dest_set)" 1>&5
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

$d_zfs list -H -o name $dest_set > /dev/null 2>&1
if [ $? != 0 ] ; then

	local head_snap="$($s_zfs list -t snapshot -H -o name $src_set | head -1)"
	local head_snap_num="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o value $head_snap)"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] head_snap = ($head_snap)" 1>&5
		echo "[DEBUG] head_snap_num = ($head_snap_num)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	printf "\n---------------------------------- ( head send ) -----------------------------------\n" 1>&4
	printf "\n---------------------------------- ( head send ) -----------------------------------\n" 1>&7


	echo "[INFO2] dest set $dest_set does NOT exist" 1>&4
	echo "[INFO1] zfs send $head_snap" 1>&3

	echo "------------------------------------------------------------------------------------" 1>&9
	$s_zfs send -pv $head_snap 2>&6 | $d_zfs recv -uv $dest_set 1>&8
	local ret=( "${PIPESTATUS[@]}" )
	sleep 0.1	# to sync logging in this spot, or it jumps order
	echo "------------------------------------------------------------------------------------" 1>&9


	if [ "${ret[0]}" != 0 ] || [ "${ret[1]}" != 0 ] ;then

		echo "[DEBUG] zfs send pipeline returns are (${ret[@]})" 1>&5

		echo "**************************************************************************************"  1>&3
		echo "[ERROR] zfs send/recv fail for $src_set " 1>&3
		echo "**************************************************************************************"  1>&3

	elif [ "$d_type" = "pri" ] && [ -n $head_snap_num ] ;then

			echo "[DEBUG] zfs set $pfix:tsnum=$head_snap_num $head_snap"  1>&5
			$s_zfs set $pfix:tsnum=$head_snap_num $head_snap

	else

		echo "[ERORR] not an error???" 1>&3

	fi

fi



########## find last matching src and dest snapshots for incr send 


for src_snap in $($s_zfs list -t snapshot -H -o name $src_set | tac ) ;do

		local snap="${src_snap#$src_set@}"

	$d_zfs list -t snapshot -H -o name $dest_set@$snap > /dev/null 2>&1
	if [ $? = 0 ] ; then

		local s_guid="$($s_zfs get guid -t snapshot -H -o value $src_snap)"
		local d_guid="$($d_zfs get guid -t snapshot -H -o value $dest_set@$snap)"

		if [ "$s_guid" = "$d_guid" ] ; then

			local match_snap="$src_snap"
			break

		fi

	fi

done


if [ -z "$match_snap" ] ;then

		echo "[ERROR] match_snap NOT found for $src_set" 1>&3
		echo "[ERROR] can NOT do incr send for $src_set" 1>&3
		return
fi



########## incremental send from last matching dest snapshot to last source snapshot


$d_zfs list -H -o name $dest_set > /dev/null 2>&1
if [ $? = 0 ] ; then

	local last_snap="$($s_zfs list -t snapshot -H -o name $src_set | tail -n 1)"
	local last_auto_snap="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o name $src_set | tail -n 1)"
	local last_auto_snap_num="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"
	local last_trans_snap="$($s_zfs get $pfix:tsnum -t snapshot -s local,received -H -o name $src_set | tail -n 1)"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] match_snap = $match_snap" 1>&5
		echo "[DEBUG] last_snap = $last_snap" 1>&5
		echo "[DEBUG] last_auto_snap = $last_auto_snap" 1>&5
		echo "[DEBUG] last_auto_snap_num = $last_auto_snap_num" 1>&5
		echo "[DEBUG] last_trans_snap = $last_trans_snap" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if [ "$last_snap" != "$match_snap" ] ;then

	printf "\n---------------------------------- ( incr send ) -----------------------------------\n" 1>&4
	printf "\n---------------------------------- ( incr send ) -----------------------------------\n" 1>&7

		echo "[INFO1] zfs send $match_snap" 1>&3
		echo "[INFO1] to ----> $last_snap" 1>&3

		echo "------------------------------------------------------------------------------------" 1>&9
		$s_zfs send -pv -I $match_snap $last_snap 2>&6 | $d_zfs recv -Fuv -x $pfix:tsnum $dest_set 1>&8
		local ret=( "${PIPESTATUS[@]}" )
		sleep 0.1	# to sync logging in this spot, or it jumps order
		echo "------------------------------------------------------------------------------------" 1>&9

		if [ "${ret[0]}" != 0 ] || [ "${ret[1]}" != 0 ]  ;then

			echo "[DEBUG] zfs send pipeline returns are (${ret[@]})" 1>&5

			echo "**************************************************************************************" 1>&3
			echo "[ERROR] zfs send/recv fail for $src_set " 1>&3
			echo "**************************************************************************************" 1>&3

		elif [ "$d_type" = pri ] && [ -n "$last_auto_snap_num" ] ;then

			echo "[DEBUG] zfs set $pfix:tsnum=$last_auto_snap_num $last_auto_snap"  1>&5
			$s_zfs set $pfix:tsnum=$last_auto_snap_num $last_auto_snap

		fi

	else

		echo "[INFO2] last snapshot $last_snap = match_snap."	1>&4
		echo "[INFO2] NO need to send $last_snap."	1>&4

	fi

else

	 echo "[ERROR] dest set $dest_set does NOT exist, can NOT send" 1>&3

fi

}



do_everything



exit



