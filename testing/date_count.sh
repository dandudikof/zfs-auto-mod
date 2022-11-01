#!/bin/bash
#
# run simulated snap/backup/prune schedule for testing
#
# desktop buttons. pause,step1,step2,step3,run script
# echo pause > /tmp/auto-pause		#pause
# echo step1 > /tmp/auto-pause		#step hourly
# echo step2 > /tmp/auto-pause		#step daily
# echo step3 > /tmp/auto-pause		#step weekly
# echo run > /tmp/auto-pause		#run
# or
# ssh user@hostname "echo pause > /tmp/auto-pause"	# for remote/virtual etc...

# (can edit/debug rest of script/configs while running and tailing logs, except this file)

echo puase > /tmp/auto-pause	# change to pause to enable paused state on start

echo -e "\n-------------------------------- $(date +%T) --------------------------------\n"

cfg1=../config/type1.cfg
cfg2=../config/type2.cfg
cfg3=../config/type3.cfg

log_dir=/ramdisk/auto

YN=2025		# year
wy=0		# week of year
dy=1		# day of year
dw=4 		# day of week (skips bakup on first day if not 1)

do_date_count() {

# count months
for my in {01..05} ;do

	for dm in {01..30} ;do
	
		# loop the day of the week and increment week in year
		[ $dw -eq 8 ] && { dw=1; ((wy++)); }
			
		[ $dw -ne 1 ] && printf "\nANOTHER  DAY --- $YN-$my-$dm ------------ \n"
		[ $dw -eq 1 ] && printf "\nANOTHER WEEK --- $YN-$my-$dm ------------ \n"

		
		#run hourly tasks
		for hd in {00..23..6} ;do # count from 00 to 23 hrs in steps of ..6 hrs for now
		
			do_pause 1

			printf "\nanother hour --- $YN-$my-$dm $hd:00:00 --- \n"
			pass="$YN $my $wy $dy $dm $dw $hd" # pass to scripts	
			#printf "\n[DEBUG] --- pass=($YN-$my-$wy-$dy-$dm-$dw-$hd) --- \n"
			
			../zfs_auto_snap.sh $cfg1 $pass
			../zfs_auto_snap.sh $cfg2 $pass
			../zfs_auto_snap.sh $cfg3 $pass

		done
		
		do_pause 2
			
		# run first day of the week tasks 
		if [ "$dw" -eq 1 ] ;then

			pass="$YN $my $wy $dy $dm $dw $hd" # pass to scripts
			#printf "\n[DEBUG] --- pass=($YN-$my-$wy-$dy-$dm-$dw-$hd) --- \n"
			
			../zfs_auto_bak.sh $cfg1 $pass
			../zfs_auto_bak.sh $cfg2 $pass
			../zfs_auto_bak.sh $cfg3 $pass
			../zfs_auto_prune-src.sh $cfg1 $pass
			../zfs_auto_prune-src.sh $cfg2 $pass
			../zfs_auto_prune-src.sh $cfg3 $pass
			../zfs_auto_prune-dest.sh $cfg1 $pass
			../zfs_auto_prune-dest.sh $cfg2 $pass
			../zfs_auto_prune-dest.sh $cfg3 $pass
			
			do_pause 3
			
		fi

		# increment day of the year and week
		((dy++)) ; ((dw++))
		
	done
done
}

do_logging () { 
	#create logdir before scripts logging kicks in, so can start tail early & clear logs
	[ ! -d "$log_dir" ] &&	mkdir "$log_dir"
	echo > $log_dir/backup.log
	echo > $log_dir/send.log
}

do_pause () {

	local call=$1	
	local count=0
	
	while [ "$(cat /tmp/auto-pause)" != run ] ;do

		printf "sleeping for %05d\033[0K\r" $count
		
		local cat="$(cat /tmp/auto-pause)"
				
		if [ "$call" = 1 ] ;then
			[ "$cat" = step1 ] && { printf "\033[0K\r"; echo "pause" > /tmp/auto-pause; return; }
			[ "$cat" = step2 ] && { printf "\033[0K\r"; return; }
			[ "$cat" = step3 ] && { printf "\033[0K\r"; return; }
		elif [ "$call" = 2 ] ;then
			[ "$cat" = step1 ] && { printf "\033[0K\r"; return; }
			[ "$cat" = step2 ] && { printf "\033[0K\r"; echo "pause" > /tmp/auto-pause; return; }
			[ "$cat" = step3 ] && { printf "\033[0K\r"; return; }
		elif [ "$call" = 3 ] ;then		
			[ "$cat" = step1 ] && { printf "\033[0K\r"; return; }
			[ "$cat" = step2 ] && { printf "\033[0K\r"; return; }
			[ "$cat" = step3 ] && { printf "\033[0K\r"; echo "pause" > /tmp/auto-pause; return; }
		else 
			return
		fi
		
		sleep 1

		((count++))

	done
}

do_logging

do_date_count

echo "this whole thing took $SECONDS sec"


