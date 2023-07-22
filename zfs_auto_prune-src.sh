#!/bin/bash



[ -z $1 ] && { echo "[ERROR] $(basename $0) NO config file provided" 1>&2; exit 1; }
source $1 || { echo "[ERROR] $(basename $0) could NOT load config file" 1>&2; exit 1; }





printf "\n" >> $log_file3
echo '================================================================================================' >> $log_file3
echo "[$DATE] [$TIME] --------------- PRUNE SRC --------------- $1" >> $log_file3
echo '================================================================================================' >> $log_file3


source $script_dir/fnc_lock-check.sh || { echo '[ERROR] NOT loaded (fnc_lock-check.sh) ' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_remote-check.sh || { echo '[ERROR] NOT loaded (fnc_remote-check.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_pool-check.sh || { echo '[ERROR] NOT loaded (fnc_pool-check.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_sort-list.sh || { echo '[ERROR] NOT loaded (fnc_sort-list.sh)' >> $log_file3; fnc_err=1; }
source $script_dir/fnc_logging.sh || { echo '[ERROR] NOT loaded (fnc_logging.sh)' >> $log_file3; fnc_err=1; }
[ "$fnc_err" = 1 ] && { echo "[ERROR] NOT running ($(basename $0)) script, missing functions" >> $log_file3; exit 1; }


do_everything() {
#printf "\n======================================( do_everything )=========================================\n\n"

				do_lock_check
				do_remote_check s
				do_pool_check s
				do_sort_list"$sort_type" #>/dev/null 3>&1
				do_prune_src"$snap_type"
				
				do_lock_clear


}



do_prune_src1() {
printf "\n--------------------------------------( do_prune_src1 )-----------------------------------------\n" 1>&4
		# type1 src pruning

for child in "${dataset_array[@]}" ;do

	local src_set="$child"
	local last_trans_snap="$($s_zfs get $pfix:tsnum -t snapshot -s local,received -H -o name $src_set | tail -n 1)"
	local last_trans_snap_num="$($s_zfs get $pfix:tsnum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"
	local last_snap_num="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"

		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] last_trans_snap = ($last_trans_snap)" 1>&5
		echo "[DEBUG] last_trans_snap_num  = ($last_trans_snap_num)" 1>&5
		echo "[DEBUG] last_snap_num = ($last_snap_num)" 1>&5
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if [ -z $last_trans_snap_num  ] && [ "$s_type" = sbp ] ;then

		echo "[info2] src_set $src_set has NOT been transfered yet , skipping prune" 1>&4

	else

		local pfix_stype="$pfix:stype:1"
		local p_list="$($s_zfs get $pfix_stype -t snapshot -s local,received -H -o name $src_set | head -n -$s_k)"
		
				#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
				echo "[DEBUG] s_k = ($s_k)" 1>&5
				echo "[DEBUG] pfix_stype = ($pfix_stype)" 1>&5
				#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
				
		if [ -z "$p_list" ] ;then
		
			echo "[info2] nothing to prune in $src_set" 1>&4
		
		else

			for p in $p_list ;do

				local p_snap_num="$($s_zfs get $pfix:snum -s local,received -H -o value $p)"

				if [ "$p_snap_num" -lt "$last_trans_snap_num" ] && [ "$s_type" = sbp ] ;then

					echo "[info1] zfs destroy $p" 1>&3
					$s_zfs destroy $p

				elif [ "$p_snap_num" -lt "$last_snap_num" ] && [ "$s_type" = sp ] ;then

					echo "[info1] zfs destroy $p" 1>&3
					$s_zfs destroy $p

				else

					echo "[info2] NOT ok to destroy $p"  1>&4

				fi

			done

		fi

	fi

	echo "------------------------------------------------------------------------------------------------" 1>&4

done

}



do_prune_src2() {
printf "\n--------------------------------------( do_prune_src2 )-----------------------------------------\n" 1>&4
		# type2 src pruning

for child in "${dataset_array[@]}" ;do

	local src_set="$child"
	local last_snap_num="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"
	local last_trans_snap="$($s_zfs get $pfix:tsnum -t snapshot -s local,received -H -o name $src_set | tail -n 1)"
	local last_trans_snap_num="$($s_zfs get $pfix:tsnum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"


		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] last_snap_num = ($last_snap_num)" 1>&5
		echo "[DEBUG] last_trans_snap = ($last_trans_snap)" 1>&5
		echo "[DEBUG] last_trans_snap_num = ($last_trans_snap_num)" 1>&5
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if  [ -z $last_trans_snap_num ] && [ "$s_type" = sbp ] ;then

		echo "[info2] src_set $src_set has NOT been transfered yet , skipping prune" 1>&4

	else

		for i in m w d h ;do

			printf '%55s\n' "--------------------[ $i ]----------------------" 1>&5

			# just for info
			local mwdh
			[ $i = m ] && mwdh=monthly
			[ $i = w ] && mwdh=weekly
			[ $i = d ] && mwdh=daily
			[ $i = h ] && mwdh=hourly

			local ls_k="s_k$i"
			local pfix_stype="$pfix:stype:2:$i"
			local p_list="$($s_zfs get $pfix_stype -t snapshot -s local,received -H -o name $src_set | head -n -${!ls_k})"
			
				#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
				echo "[DEBUG] mwdh = ($mwdh)" 1>&5
				echo "[DEBUG] ls_k = (${!ls_k})" 1>&5
				echo "[DEBUG] pfix_stype = ($pfix_stype)" 1>&5
				#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

			if [ -z "$p_list" ] ;then

				echo "[info2] nothing to prune for ${mwdh} in $src_set" 1>&4

			else

				for p in $p_list ;do

					local p_snap_num="$($s_zfs get $pfix:snum -s local,received -H -o value $p)"

					if [ "$p_snap_num" -lt "$last_trans_snap_num" ] && [ "$s_type" = sbp ] ;then

						echo "[info1] zfs destroy $p" 1>&3
						$s_zfs destroy $p

					elif [ "$p_snap_num" -lt "$last_snap_num" ] && [ "$s_type" = sp ] ;then

						echo "[info1] zfs destroy $p" 1>&3
						$s_zfs destroy $p

					else

						echo "[info2] NOT ok to destroy $p"  1>&4
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



