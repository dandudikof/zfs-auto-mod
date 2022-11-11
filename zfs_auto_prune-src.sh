#!/bin/bash



#config file and functions
source $1; [ "$?" != 0 ] && { echo 'no config file' 1>&2; exit 1; }
source $script_dir/fnc_logging.sh; [ "$?" != 0 ] && { echo 'no fnc_logging.sh' 1>&2; exit 1; }
source $script_dir/fnc_lock-check.sh; [ "$?" != 0 ] && { echo 'no fnc_lock_check.sh' 1>&2; exit 1; }
source $script_dir/fnc_pool-check.sh; [ "$?" != 0 ] && { echo 'no fnc_pool_check.sh' 1>&2; exit 1; }
source $script_dir/fnc_remote-check.sh; [ "$?" != 0 ] && { echo 'no fnc_remote_check.sh' 1>&2; exit 1; }
source $script_dir/fnc_sort-list.sh; [ "$?" != 0 ] && { echo 'no fnc_sort_list.sh' 1>&2; exit 1; }






printf "\n" 1>&3
echo '================================================================================================' 1>&3
echo "[$DATE] [$TIME] ---------------- PRUNE SRC ---------------- $1" 1>&3
echo '================================================================================================' 1>&3
#printf "\n"



do_everything() {
#printf "\n==================================== DO_EVERYTHING ======================================\n\n"

				do_lock_check
				do_pool_check1
				do_remote_check1
				do_sort_list"$sort_type" #>/dev/null 3>&1
				do_prune_src"$snap_type"
				
				do_lock_clear


}



do_prune_src1() {
printf "\n---------------------------------- do_prune_src1 -----------------------------------\n" 1>&4
		# type1 src pruning
		

for child in "${dataset_i_array[@]}" ;do

	local src_set="$child"
	local last_trans_snap="$($s_zfs get $pfix:tsnum -t snapshot -s local,received -H -o name $src_set | tail -n 1)"
	local last_trans_snap_num="$($s_zfs get $pfix:tsnum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"
	local last_snap_num="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] last_trans_snap = ($last_trans_snap)" 1>&5
		echo "[DEBUG] last_trans_snap_num  = ($last_trans_snap_num)" 1>&5
		echo "[DEBUG] last_snap_num = ($last_snap_num)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if [ -z $last_trans_snap_num  ] && [ "$s_type" = sbp ] ;then

		echo "[INFO2] src_set $src_set has NOT been transfered yet , skipping prune" 1>&4

	else

		local pfix_stype="$pfix:stype:1"
		local p_list="$($s_zfs get $pfix_stype -t snapshot -s local,received -H -o name $src_set | head -n -$s_k)"

		if [ -z "$p_list" ] ;then
			echo "[INFO1] nothing to prune in $src_set" 1>&3
			continue
		fi

		for p in $p_list ;do

			local p_snap_num="$($s_zfs get $pfix:snum -s local,received -H -o value $p)"

			if [ "$p_snap_num" -lt "$last_trans_snap_num" ] && [ "$s_type" = sbp ] ;then

				echo "[INFO1] zfs destroy $p" 1>&3
				$s_zfs destroy $p

			elif [ "$p_snap_num" -lt "$last_snap_num" ] && [ "$s_type" = sp ] ;then

				echo "[INFO1] zfs destroy $p" 1>&3
				$s_zfs destroy $p

			else

				echo "[INFO2] NOT ok to destroy $p"  1>&4

			fi

		done

	fi

	echo "------------------------------------------------------------------------------------" 1>&4

done

}



do_prune_src2() {
printf "\n---------------------------------- do_prune_src2 -----------------------------------\n" 1>&4
		# type2 src pruning


for child in "${dataset_i_array[@]}" ;do

	local src_set="$child"
	local last_trans_snap="$($s_zfs get $pfix:tsnum -t snapshot -s local,received -H -o name $src_set | tail -n 1)"
	local last_trans_snap_num="$($s_zfs get $pfix:tsnum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"
	local last_snap_num="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] last_trans_snap = ($last_trans_snap)" 1>&5
		echo "[DEBUG] last_trans_snap_num  = ($last_trans_snap_num)" 1>&5
		echo "[DEBUG] last_snap_num = ($last_snap_num)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if  [ -z $last_trans_snap_num  ] && [ "$s_type" = sbp ] ;then

		echo "[INFO2] src_set $src_set has NOT been transfered yet , skipping prune" 1>&4

	else

		for i in m w d ;do

			# just for info
			local mwdh
			[ "$i" = "m" ] && mwdh=month
			[ "$i" = "w" ] && mwdh=week
			[ "$i" = "d" ] && mwdh=day
			
			local ls_k="s_k$i"
			local pfix_stype="$pfix:stype:2:$i"
			local p_list="$($s_zfs get $pfix_stype -t snapshot -s local,received -H -o name $src_set | head -n -${!ls_k})"

			if [ -z "$p_list" ] ;then
				echo "[INFO2] nothing to prune for ${mwdh}ly in $src_set" 1>&4
				continue
			fi

			for p in $p_list ;do

				local p_snap_num="$($s_zfs get $pfix:snum -s local,received -H -o value $p)"

				if [ "$p_snap_num" -lt "$last_trans_snap_num" ] && [ "$s_type" = sbp ] ;then

					echo "[INFO1] zfs destroy $p" 1>&3
					$s_zfs destroy $p

				elif [ "$p_snap_num" -lt "$last_snap_num" ] && [ "$s_type" = sp ] ;then

					echo "[INFO1] zfs destroy $p" 1>&3
					$s_zfs destroy $p

				else

					echo "[INFO2] NOT ok to destroy $p"  1>&4
				fi

			done

		done

	fi

	echo "------------------------------------------------------------------------------------" 1>&4

done

}



do_prune_src3() {
printf "\n---------------------------------- do_prune_src3 -----------------------------------\n" 1>&4
		# type3 src pruning


for child in "${dataset_i_array[@]}" ;do

	local src_set="$child"
	local last_snap_num="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"
	local last_trans_snap="$($s_zfs get $pfix:tsnum -t snapshot -s local,received -H -o name $src_set | tail -n 1)"
	local last_trans_snap_num="$($s_zfs get $pfix:tsnum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"


		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] last_snap_num = ($last_snap_num)" 1>&5
		echo "[DEBUG] last_trans_snap = ($last_trans_snap)" 1>&5
		echo "[DEBUG] last_trans_snap_num = ($last_trans_snap_num)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if  [ -z $last_trans_snap_num ] && [ "$s_type" = sbp ] ;then

		echo "[INFO2] src_set $src_set has NOT been transfered yet , skipping prune" 1>&4

	else

		for i in m w d h ;do

			# just for info
			local mwdh
			[ $i = m ] && mwdh=month
			[ $i = w ] && mwdh=week
			[ $i = d ] && mwdh=day
			[ $i = h ] && mwdh=hour

			local ls_k="s_k$i"
			local pfix_stype="$pfix:stype:3:$i"
			local p_list="$($s_zfs get $pfix_stype -t snapshot -s local,received -H -o name $src_set | head -n -${!ls_k})"

			if [ -z "$p_list" ] ;then
				echo "[INFO2] nothing to prune for ${mwdh}ly in $src_set" 1>&4
				continue
			fi

			for p in $p_list ;do

				local p_snap_num="$($s_zfs get $pfix:snum -s local,received -H -o value $p)"

				if [ "$p_snap_num" -lt "$last_trans_snap_num" ] && [ "$s_type" = sbp ] ;then

					echo "[INFO1] zfs destroy $p" 1>&3
					$s_zfs destroy $p

				elif [ "$p_snap_num" -lt "$last_snap_num" ] && [ "$s_type" = sp ] ;then

					echo "[INFO1] zfs destroy $p" 1>&3
					$s_zfs destroy $p

				else

					echo "[INFO2] NOT ok to destroy $p"  1>&4
				fi

			done

		done

	fi

	echo "------------------------------------------------------------------------------------" 1>&4

done

}



do_everything



exit



