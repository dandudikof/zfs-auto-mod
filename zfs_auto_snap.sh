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
echo "[$DATE] [$TIME] ---------------- SNAP ---------------- $1" 1>&3
echo '================================================================================================' 1>&3
#printf "\n"



do_everything() {
#printf "\n==================================== DO_EVERYTHING ======================================\n\n"

				do_lock_check $1
				do_pool_check1
				do_remote_check1
				do_sort_list"$sort_type" #>/dev/null 3>&1
				do_snap_parent
				do_snap_dataset"$snap_type"
				do_lock_clear $1


}



do_snap_parent() {
printf "\n---------------------------------- do_snap_parent ----------------------------------\n" 1>&4
			# snaps s_pool and parent datasets to set@$pfix-parent


for child in "${parent_i_array[@]}" ;do

	local src_set=$child
	local parent_check="$($s_zfs list -H -o name $src_set@$pfix-parent 2> /dev/null)"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] parent_check = ($parent_check)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5


	if [ -n "$parent_check" ] ;then

		echo "[INFO2] parent snapshot $src_set@$pfix-parent exists" 1>&4

	else

		echo "[INFO2] parent snapshot $src_set@$pfix-parent does NOT exist" 1>&4
		echo "[INFO1] zfs snapshot $src_set@$pfix-parent" 1>&3

		$s_zfs snapshot $src_set@$pfix-parent

	fi

	echo "------------------------------------------------------------------------------------" 1>&5

done

}



do_snap_dataset1() {
printf "\n---------------------------------- do_snap_dataset1 ----------------------------------\n" 1>&4
		# type1 snap


for child in "${dataset_i_array[@]}" ;do

	local src_set="$child"
	local last_snap="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o name $src_set | tail -n 1)"
	local snap_num="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"
	local written_size="$($s_zfs get written -H -p -o value $src_set)"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] last_snap = ($last_snap)" 1>&5
		echo "[DEBUG] last_snap_num = ($snap_num)" 1>&5
		echo "[DEBUG] written_size = ($written_size)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	((snap_num++))
	
	local pfix_stype="$pfix:stype:1"
	local pfix_sdate="$pfix:sdate:$Yn:$my:$wy:$dm:$hd"
	local snap_check="$($s_zfs get $pfix_sdate -t snapshot -s local,received -H -o name $src_set)"
	local minws_check="$($s_zfs get $pfix:minws -t filesystem -s local,received,inherited -H -o value $src_set)"
	local current_snap="$src_set@${pfix}-t1-${DATE}_${TIME}-n$snap_num"

	[ -z "$minws_check" ] && minws_check=0

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] pfix_stype = ($pfix_stype)" 1>&5
		echo "[DEBUG] pfix_sdate = ($pfix_sdate)" 1>&5
		echo "[DEBUG] snap_check = ($snap_check)" 1>&5
		echo "[DEBUG] minws_check = ($minws_check)" 1>&5
		echo "[DEBUG] current_snap = ($current_snap)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if [ -n "$snap_check" ] ;then

		echo "[INFO2] snapshot $snap_check allready exists" 1>&4
		echo "[INFO2] NOT doing zfs snapshot $current_snap" 1>&4
		
	elif [ "$written_size" -lt "$minws_check" ] && [ -n "$last_snap" ] ;then

		echo "[INFO2] minimal usage has NOT reached min_wsize = ($minws_check) bytes" 1>&4
		echo "[INFO2] NOT doing zfs snapshot $current_snap" 1>&4

	else

		echo "[INFO2] minimal usage has reached set min_wsize = ($minws_check) bytes" 1>&4
		echo "[INFO1] zfs snapshot $current_snap" 1>&3
		$s_zfs snapshot -o $pfix_stype= -o $pfix_sdate= -o $pfix:snum=$snap_num $current_snap

	fi

	echo "------------------------------------------------------------------------------------" 1>&4

done

}



do_snap_dataset2() {
printf "\n---------------------------------- do_snap_dataset2 ----------------------------------\n" 1>&4
		# type2 snap


for child in "${dataset_i_array[@]}" ;do

	local src_set="$child"
	local last_snap="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o name $src_set | tail -n 1)"
	local snap_num="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] last_snap = ($last_snap)" 1>&5
		echo "[DEBUG] last_snap_num = ($snap_num)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	local i
	local mwdh	#just for info
	local pfix_stype
	local pfix_sdate

	if [ "$dm" -eq 1 ] ;then
		i=m
		mwdh=month
		pfix_stype="$pfix:stype:2:m"
		pfix_sdate="$pfix:sdate:$Yn:$my"
	elif [ "$dw" -eq 1 ] ;then
		i=w
		mwdh=week
		pfix_stype="$pfix:stype:2:w"
		pfix_sdate="$pfix:sdate:$Yn:$my:$wy"
	else
		i=d
		mwdh=day
		pfix_stype="$pfix:stype:2:d"
		pfix_sdate="$pfix:sdate:$Yn:$my:$wy:$dm"
	fi

	((snap_num++))
	
	local snap_check="$($s_zfs get $pfix_sdate -t snapshot -s local,received -H -o name $src_set)"
	local current_snap="$src_set@${pfix}-t2-${DATE}_${TIME}-${i}"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] pfix_stype = ($pfix_stype)" 1>&5
		echo "[DEBUG] pfix_sdate = ($pfix_sdate)" 1>&5
		echo "[DEBUG] snap_check = ($snap_check)" 1>&5
		echo "[DEBUG] current_snap = ($current_snap)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if [ -n "$snap_check" ] ;then

		echo "[INFO2] snapshot $snap_check allready exists" 1>&4
		echo "[INFO2] NOT doing zfs snapshot $current_snap" 1>&4

	else

		echo "[INFO2] snapshot $current_snap does NOT exist" 1>&4
		echo "[INFO1] zfs snapshot $current_snap" 1>&3
		$s_zfs snapshot -o $pfix_stype= -o $pfix_sdate= -o $pfix:snum=$snap_num $current_snap

	fi

	echo "------------------------------------------------------------------------------------" 1>&4

done

}



do_snap_dataset3() {
printf "\n---------------------------------- do_snap_dataset3 ----------------------------------\n" 1>&4
		# type3 snap


for child in "${dataset_i_array[@]}" ;do

	local src_set="$child"
	local last_snap="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o name $src_set | tail -n 1)"
	local snap_num="$($s_zfs get $pfix:snum -t snapshot -s local,received -H -o value $src_set | tail -n 1)"

		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] last_snap = ($last_snap)" 1>&5
		echo "[DEBUG] last_snap_num = ($snap_num)" 1>&5
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	for i in m w d h ;do
	
		# just for info
		local mwdh
		[ $i = m ] && mwdh=month
		[ $i = w ] && mwdh=week
		[ $i = d ] && mwdh=day
		[ $i = h ] && mwdh=hour

		local pfix_sdate
		[ $i = m ] && pfix_sdate="$pfix:sdate:$Yn:$my"
		[ $i = w ] && pfix_sdate="$pfix:sdate:$Yn:$my:$wy"
		[ $i = d ] && pfix_sdate="$pfix:sdate:$Yn:$my:$wy:$dm"
		[ $i = h ] && pfix_sdate="$pfix:sdate:$Yn:$my:$wy:$dm:$hd"

		((snap_num++))
		
		local pfix_stype="$pfix:stype:3:$i"
		local need_snap="$($s_zfs get $pfix:nsnap:$i -t filesystem -s local,received,inherited -H -o value $src_set)"
		local snap_check="$($s_zfs get $pfix_sdate -t snapshot -s local,received -H -o name $src_set)"
		local current_snap="$src_set@${pfix}-t3-${DATE}_${TIME}-${i}"

			echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
			echo "[DEBUG] pfix_sdate = ($pfix_sdate)" 1>&5
			echo "[DEBUG] pfix_stype = ($pfix_stype)" 1>&5
			echo "[DEBUG] need_snap = ($need_snap)" 1>&5
			echo "[DEBUG] snap_check = ($snap_check)" 1>&5
			echo "[DEBUG] current_snap = ($current_snap)" 1>&5
			echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

		if  [ "$need_snap" = 0 ] ;then
			
			echo "[INFO2] NO need for ${mwdh}'ly snapshot in $src_set" 1>&4

		elif [ -n "$snap_check" ] ;then

			echo "[INFO2] snapshot $snap_check exists" 1>&4
			echo "[INFO2] NOT doing zfs snapshot $current_snap" 1>&4

		else

			echo "[INFO2] snapshot $current_snap does NOT exist" 1>&4
			echo "[INFO1] zfs snapshot $current_snap" 1>&3

			$s_zfs snapshot -o $pfix_stype= -o $pfix_sdate= -o $pfix:snum=$snap_num $current_snap

			break	# will take weekly daily hourly at next iteration. (not at same time)
					# comented out will take them (at at same time)

		fi

		echo "------------------------------------------------------------------------------------" 1>&4
		#printf "\n"

	done


done

}



do_everything



exit



