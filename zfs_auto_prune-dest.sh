#!/bin/bash



#config file and functions
source $1; [ "$?" != 0 ] && { echo 'no config file' 1>&2; exit 1; }
source $script_dir/fnc_logging.sh; [ "$?" != 0 ] && { echo 'no fnc_logging.sh' 1>&2; exit 1; }

source $script_dir/fnc_pool-check.sh; [ "$?" != 0 ] && { echo 'no fnc_pool_check.sh' 1>&2; exit 1; }
source $script_dir/fnc_remote-check.sh; [ "$?" != 0 ] && { echo 'no fnc_remote_check.sh' 1>&2; exit 1; }
source $script_dir/fnc_sort-list.sh; [ "$?" != 0 ] && { echo 'no fnc_sort_list.sh' 1>&2; exit 1; }






printf "\n" 1>&3
echo '================================================================================================' 1>&3
echo "[$DATE] [$TIME] ---------------- PRUNE DEST ---------------- $1" 1>&3
echo '================================================================================================' 1>&3
#printf "\n"



do_everything() {
#printf "\n==================================== DO_EVERYTHING ======================================\n\n"


				do_pool_check1
				do_remote_check1
				do_sort_list"$sort_type" #>/dev/null 3>&1
				do_prune_dest"$snap_type"




}



do_prune_dest1() {
printf "\n---------------------------------- do_prune_dest1 ----------------------------------\n" 1>&4
		# type1 dest pruning


for child in "${dataset_i_array[@]}" ;do

	local src_set="$child"
	local dest_set="$d_path/$child"
	local last_dest_snap_num="$($d_zfs get $pfix:snum -t snapshot -s received -H -o value $dest_set | tail -n 1)"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] dest_set = ($dest_set)" 1>&5
		echo "[DEBUG] last_dest_snap_num = ($last_dest_snap_num)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if [ -z $last_dest_snap_num  ] ;then

		echo "[INFO2] dest_set $dest_set has NOT been transfered yet , skipping prune" 1>&4

	else

		local pfix_stype="$pfix:stype:1"
		local p_list="$($d_zfs get $pfix_stype -t snapshot -s received -H -o name  $dest_set  | head -n -$d_k)"

		if [ -z "$p_list" ] ;then
			echo "[INFO1] nothing to prune in $dest_set" 1>&3
			continue
		fi

		for p in $p_list ;do

			local p_snap_num="$($d_zfs get $pfix:snum -s received -H -o value $p)"

			if [ "$p_snap_num" -lt "$last_dest_snap_num" ]  ;then

				echo "[INFO1] zfs destroy $p" 1>&3
				$d_zfs destroy $p

			else

				echo "[INFO2] NOT ok to destroy $p"  1>&4

			fi

		done

	fi

	echo "------------------------------------------------------------------------------------" 1>&4

done

}



do_prune_dest2() {
printf "\n---------------------------------- do_prune_dest2 ----------------------------------\n" 1>&4
		# type2 dest pruning


for child in "${dataset_i_array[@]}" ;do

	local src_set="$child"
	local dest_set="$d_path/$child"
	local last_dest_snap_num="$($d_zfs get $pfix:snum -t snapshot -s received -H -o value $dest_set | tail -n 1)"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] dest_set = ($dest_set)" 1>&5
		echo "[DEBUG] last_dest_snap_num = ($last_dest_snap_num)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if  [ -z $last_dest_snap_num  ] ;then

		echo "[INFO2] dest set $dest_set has NOT been transfered yet , skipping prune" 1>&4

	else

		for i in m w d ;do

			# just for info
			local mwdh
			[ "$i" = "m" ] && mwdh=month
			[ "$i" = "w" ] && mwdh=week
			[ "$i" = "d" ] && mwdh=day

			local ld_k="d_k$i"
			local pfix_stype="$pfix:stype:2:$i"
			local p_list="$($d_zfs get $pfix_stype -t snapshot -s received -H -o name $dest_set | head -n -${!ld_k})"

			if [ -z "$p_list" ] ;then
				echo "[INFO2] nothing to prune for ${mwdh}ly in $dest_set" 1>&4
				continue
			fi

			for p in $p_list ;do

				local p_snap_num="$($d_zfs get $pfix:snum -s received -H -o value $p)"

				if [ "$p_snap_num" -lt "$last_dest_snap_num" ]  ;then

					echo "[INFO1] zfs destroy $p" 1>&3
					$d_zfs destroy $p

				else
					echo "[INFO2] NOT ok to destroy $p"  1>&4
				fi

			done

		done

	fi

	echo "------------------------------------------------------------------------------------" 1>&4

done

}



do_prune_dest3() {
printf "\n---------------------------------- do_prune_dest3 ----------------------------------\n" 1>&4
		# type3 dest pruning


for child in "${dataset_i_array[@]}" ;do

	local src_set="$child"
	local dest_set="$d_path/$child"
	local last_dest_snap_num="$($d_zfs get $pfix:snum -t snapshot -s received -H -o value $dest_set | tail -n 1)"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] dest_set = ($dest_set)" 1>&5
		echo "[DEBUG] last_dest_snap_num = ($last_dest_snap_num)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if  [ -z $last_dest_snap_num  ] ;then

		echo "[INFO2] dest set $dest_set has NOT been transfered yet , skipping prune" 1>&4

	else

		for i in m w d h ;do

			# just for info
			local mwdh
			[ $i = m ] && mwdh=month
			[ $i = w ] && mwdh=week
			[ $i = d ] && mwdh=day
			[ $i = h ] && mwdh=hour

			local ld_k="d_k$i"
			local pfix_stype="$pfix:stype:3:$i"
			local p_list="$($d_zfs get $pfix_stype -t snapshot -s received -H -o name $dest_set | head -n -${!ld_k})"

			if [ -z "$p_list" ] ;then
				echo "[INFO2] nothing to prune for ${mwdh}ly in $dest_set" 1>&4
				continue
			fi

			for p in $p_list ;do

				local p_snap_num="$($d_zfs get $pfix:snum -s received -H -o value $p)"

				if [ "$p_snap_num" -lt "$last_dest_snap_num" ]  ;then

					echo "[INFO1] zfs destroy $p" 1>&3
					$d_zfs destroy $p

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



