#!/bin/bash



[ -z $1 ] && { echo "[ERROR] $(basename $0) NO config file provided" 1>&2; exit 1; }
source $1 || { echo "[ERROR] $(basename $0) could NOT load config file" 1>&2; exit 1; }





printf "\n" >> $log_file3
echo '================================================================================================' >> $log_file3
echo "[$DATE] [$TIME] --------------- SNAP --------------- $1" >> $log_file3
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
				do_remote_check1 s
				do_pool_check1 s
				do_sort_list"$sort_type" #>/dev/null 3>&1
				do_snap_parent
				do_snap_dataset"$snap_type"
				do_lock_clear $1


}



do_snap_parent() {
printf "\n--------------------------------------( do_snap_parent )----------------------------------------\n" 1>&4
			# snaps s_pool and parent datasets to set@$pfix-parent


for child in "${parent_array[@]}" ;do

	local src_set=$child
	local parent_check="$($s_zfs list -H -o name $src_set@$pfix-parent 2> /dev/null)"

		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] parent_check = ($parent_check)" 1>&5
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5


	if [ -n "$parent_check" ] ;then

		echo "[info2] parent snapshot $src_set@$pfix-parent exists" 1>&4

	else

		echo "[info2] parent snapshot $src_set@$pfix-parent does NOT exist" 1>&4
		echo "[info1] zfs snapshot $src_set@$pfix-parent" 1>&3

		$s_zfs snapshot $src_set@$pfix-parent

	fi

	echo "------------------------------------------------------------------------------------------------" 1>&4

done

}



do_snap_dataset1() {
printf "\n--------------------------------------( do_snap_dataset1 )--------------------------------------\n" 1>&4
		# type1 snap


for child in "${dataset_array[@]}" ;do

	local src_set="$child"
	local last_snap="$($s_zfs get -t snapshot -s local,received -H -o name $pfix:snum $src_set | tail -n 1)"
	local snap_num="$($s_zfs get -t snapshot -s local,received -H -o value $pfix:snum $src_set | tail -n 1)"
	local written_size="$($s_zfs get -H -p -o value written $src_set)"

		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] last_snap = ($last_snap)" 1>&5
		echo "[DEBUG] last_snap_num = ($snap_num)" 1>&5
		echo "[DEBUG] written_size = ($written_size)" 1>&5
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	((snap_num++))
	
	local pfix_stype="$pfix:stype:1"
	local pfix_sdate="$pfix:sdate:$Yn:$my:$wy:$dm:$hd"
	local snap_check="$($s_zfs get -t snapshot -s local,received -H -o name $pfix_sdate $src_set)"
	local minws_check="$($s_zfs get -s local,received,inherited -H -o value $pfix:minws $src_set)"
	local current_snap="$src_set@${pfix}-t1-${DATE}_${TIME}-n$snap_num"

	[ -z "$minws_check" ] && minws_check=0

		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] pfix_stype = ($pfix_stype)" 1>&5
		echo "[DEBUG] pfix_sdate = ($pfix_sdate)" 1>&5
		echo "[DEBUG] snap_check = ($snap_check)" 1>&5
		echo "[DEBUG] minws_check = ($minws_check)" 1>&5
		echo "[DEBUG] current_snap = ($current_snap)" 1>&5
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	if [ -n "$snap_check" ] ;then

		echo "[info2] snapshot $snap_check allready exists" 1>&4
		echo "[info2] NOT doing zfs snapshot $current_snap" 1>&4
		
	elif [ "$written_size" -lt "$minws_check" ] && [ -n "$last_snap" ] ;then

		echo "[info2] minimal usage has NOT reached min_wsize = ($minws_check) bytes" 1>&4
		echo "[info2] NOT doing zfs snapshot $current_snap" 1>&4

	else

		echo "[info2] minimal usage has reached set min_wsize = ($minws_check) bytes" 1>&4
		echo "[info1] zfs snapshot $current_snap" 1>&3
		$s_zfs snapshot -o $pfix_stype= -o $pfix_sdate= -o $pfix:snum=$snap_num $current_snap

	fi

	echo "------------------------------------------------------------------------------------------------" 1>&4

done

}



do_snap_dataset2() {
printf "\n--------------------------------------( do_snap_dataset2 )--------------------------------------\n" 1>&4
		# type2 snap


for child in "${dataset_array[@]}" ;do

	local src_set="$child"
	local last_snap="$($s_zfs get -t snapshot -s local,received -H -o name $pfix:snum $src_set | tail -n 1)"
	local snap_num="$($s_zfs get -t snapshot -s local,received -H -o value $pfix:snum $src_set | tail -n 1)"
	local written_size="$($s_zfs get -H -p -o value written $src_set)"
	
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
		echo "[DEBUG] src_set = ($src_set)" 1>&5
		echo "[DEBUG] last_snap = ($last_snap)" 1>&5
		echo "[DEBUG] last_snap_num = ($snap_num)" 1>&5
		echo "[DEBUG] written_size = ($written_size)" 1>&5
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

	for i in m w d h ;do

		printf '%54s\n' "--------------------[ $i ]----------------------" 1>&5

		# just for info
		local mwdh
		[ $i = m ] && mwdh=month
		[ $i = w ] && mwdh=week
		[ $i = d ] && mwdh=dai
		[ $i = h ] && mwdh=hour

		local pfix_sdate
		[ $i = m ] && pfix_sdate="$pfix:sdate:$Yn:$my"
		[ $i = w ] && pfix_sdate="$pfix:sdate:$Yn:$my:$wy"
		[ $i = d ] && pfix_sdate="$pfix:sdate:$Yn:$my:$wy:$dm"
		[ $i = h ] && pfix_sdate="$pfix:sdate:$Yn:$my:$wy:$dm:$hd"

		((snap_num++))
		
		local pfix_stype="$pfix:stype:2:$i"
		local need_snap="$($s_zfs get -s local,received,inherited -H -o value $pfix:nsnap:$i $src_set)"
		local snap_check="$($s_zfs get -t snapshot -s local,received -H -o name $pfix_sdate $src_set)"
		local minws_check="$($s_zfs get -s local,received,inherited -H -o value $pfix:minws:$i $src_set)"
		local current_snap="$src_set@${pfix}-t2-${DATE}_${TIME}-${i}"
		
		[ -z "$minws_check" ] && minws_check=0
		
			#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5
			echo "[DEBUG] mwdh = ($mwdh)" 1>&5
			echo "[DEBUG] pfix_stype = ($pfix_stype)" 1>&5
			echo "[DEBUG] pfix_sdate = ($pfix_sdate)" 1>&5
			echo "[DEBUG] need_snap = ($need_snap)" 1>&5
			echo "[DEBUG] snap_check = ($snap_check)" 1>&5
			echo "[DEBUG] minws_check = ($minws_check)" 1>&5
			echo "[DEBUG] current_snap = ($current_snap)" 1>&5
			#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 1>&5

		if  [ "$need_snap" = 0 ] ;then
			
			echo "[info2] NO need for ${mwdh}ly snapshots in $src_set" 1>&4

		elif [ -n "$snap_check" ] ;then

			echo "[info2] ${mwdh}ly snapshot $snap_check exists" 1>&4
			echo "[info2] NOT doing zfs snapshot $current_snap" 1>&4
			
		elif [ "$written_size" -lt "$minws_check" ] && [ -n "$last_snap" ] ;then

			echo "[info2] ${mwdh}ly snapshot has NOT reached min_wsize = ($minws_check) bytes" 1>&4
			echo "[info2] NOT doing zfs snapshot $current_snap" 1>&4

		else

			echo "[info2] ${mwdh}ly snapshot $current_snap does NOT exist" 1>&4
			echo "[info1] zfs snapshot $current_snap" 1>&3

			$s_zfs snapshot -o $pfix_stype= -o $pfix_sdate= -o $pfix:snum=$snap_num $current_snap

			break	# will take weekly daily hourly at next iteration. (not at same time)
					# comented out will take them (at at same time)

		fi

	done

	echo "------------------------------------------------------------------------------------------------" 1>&4

done

}



do_everything



exit



