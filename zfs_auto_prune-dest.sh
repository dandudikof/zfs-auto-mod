#!/bin/bash

v=1.01

[ -z $1 ] && { echo "[ERROR] $(basename $0) NO config file provided" 1>&2; exit 1; }
source $1 || { echo "[ERROR] $(basename $0) could NOT load config file" 1>&2; exit 1; }

[ -d "$log_dir" ] || mkdir -p "$log_dir" || { echo "[ERROR] $(basename $0) Unable to create $log_dir" 1>&2; exit 1; }
[ -w "$log_file3" ] || touch "$log_file3" || { echo "[ERROR] $(basename $0) Unable to create $log_file3" 1>&2; exit 1; }






printf "\n" >> $log_file3
echo '================================================================================================' >> $log_file3
echo "[$DATE] [$TIME] ---------- $(basename $0) v$v ---------- $1" >> $log_file3
echo '================================================================================================' >> $log_file3


source $script_dir/fnc_compatibility.sh || { echo '[ERROR] NOT loaded (fnc_compatibility.sh) ' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_lock-check.sh || { echo '[ERROR] NOT loaded (fnc_lock-check.sh) ' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_remote-check.sh || { echo '[ERROR] NOT loaded (fnc_remote-check.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_pool-check.sh || { echo '[ERROR] NOT loaded (fnc_pool-check.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_sort-list.sh || { echo '[ERROR] NOT loaded (fnc_sort-list.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_logging.sh || { echo '[ERROR] NOT loaded (fnc_logging.sh)' >> $log_file3; fnc_err=1; }
[ "$fnc_err" = 1 ] && { echo "[ERROR] NOT running ($(basename $0)) script, missing functions" >> $log_file3; exit 1; }


do_everything() {
#printf "\n======================================( do_everything )=========================================\n\n"

				do_lock_check
				do_remote_check
				do_pool_check
				do_sort_list
				do_prune_dest"$snap_type"
				
				do_lock_clear


}



do_prune_dest1() {
printf "\n--------------------------------------( do_prune_dest1 )----------------------------------------\n" 1>&4
		# type1 dest pruning

for src_set in "${dataset_array[@]}" ;do

	local dest_set="${dest_Array[$src_set]}"
	local last_dest_num="$($d_zfs get -t snapshot -s received -H -o value $pfix:snum $dest_set 2>/dev/null | tail -n 1)"

		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] dest_set = ($dest_set)" 1>&5
		echo "[DEBUG] last_dest_num = ($last_dest_num)" 1>&5
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if ! $d_zfs list -H -o name $dest_set > /dev/null 2>&1 ;then

		echo "[info2] dest_set $dest_set does NOT exists, skipping prune" 1>&4

	elif [ -z $last_dest_num ] ;then

		echo "[info2] dest set $dest_set has NO auto snapshots, skipping prune" 1>&4

	else

		local pfix_stype="$pfix:stype:1"

			#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
			echo "[DEBUG] d_k = ($d_k)" 1>&5
			echo "[DEBUG] pfix_stype = ($pfix_stype)" 1>&5
			#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

		local p_list="$($d_zfs get -t snapshot -s received -H -o name $pfix_stype $dest_set | head -n -$d_k)"

		if [ -z "$p_list" ] ;then

			echo "[info2] nothing to prune in $dest_set" 1>&4

		else

			for p in $p_list ;do

				local p_num="$($d_zfs get -s received -H -o value $pfix:snum $p)"

				if [ "$p_num" -lt "$last_dest_num" ] ;then

					echo "[info1] zfs destroy $p" 1>&3
					$d_zfs destroy $p

				else

					echo "[info2] NOT ok to destroy $p" 1>&4

				fi

			done

		fi

	fi

	echo "------------------------------------------------------------------------------------------------" 1>&4

done

}



do_prune_dest2() {
printf "\n--------------------------------------( do_prune_dest2 )----------------------------------------\n" 1>&4
		# type2 dest pruning

for src_set in "${dataset_array[@]}" ;do

	local dest_set="${dest_Array[$src_set]}"
	local last_dest_num="$($d_zfs get -t snapshot -s received -H -o value $pfix:snum $dest_set 2>/dev/null | tail -n 1)"

		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] dest_set = ($dest_set)" 1>&5
		echo "[DEBUG] last_dest_num = ($last_dest_num)" 1>&5
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if ! $d_zfs list -H -o name $dest_set > /dev/null 2>&1 ;then

		echo "[info2] dest_set $dest_set does NOT exists, skipping prune" 1>&4

	elif [ -z $last_dest_num ] ;then

		echo "[info2] dest set $dest_set has NO auto snapshots, skipping prune" 1>&4

	else

		for i in m w d h ;do
		
			printf '%55s\n' "--------------------[ $i ]----------------------" 1>&5
			
			# just for info
			local mwdh
			[ $i = m ] && mwdh=monthly
			[ $i = w ] && mwdh=weekly
			[ $i = d ] && mwdh=daily
			[ $i = h ] && mwdh=hourly

			local ld_k="d_k$i"
			local pfix_stype="$pfix:stype:2:$i"

				#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
				echo "[DEBUG] mwdh = ($mwdh)" 1>&5
				echo "[DEBUG] ld_k = (${!ld_k})" 1>&5
				echo "[DEBUG] pfix_stype = ($pfix_stype)" 1>&5
				#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

			local p_list="$($d_zfs get -t snapshot -s received -H -o name $pfix_stype $dest_set | head -n -${!ld_k})"

			if [ -z "$p_list" ] ;then

				echo "[info2] nothing to prune for ${mwdh} in $dest_set" 1>&4

			else

				for p in $p_list ;do

					local p_num="$($d_zfs get -s received -H -o value $pfix:snum $p)"

					if [ "$p_num" -lt "$last_dest_num" ] ;then

						echo "[info1] zfs destroy $p" 1>&3
						$d_zfs destroy $p

					else

						echo "[info2] NOT ok to destroy $p" 1>&4

					fi

				done

			fi

		done

	fi

	echo "------------------------------------------------------------------------------------------------" 1>&4

done

}



do_everything



exit



