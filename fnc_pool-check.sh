#
#	if do_pool_check fails it exits with 1 and stops script, else returns 0 and continues
#





do_pool_check1() {
printf "\n---------------------------------- do_pool_check1 --------------------------------\n" 1>&4
			# tested (once)
			
local l_pool

for l_pool in $s_pool ;do

	local pool_health="$($s_srv $zpool list -H -o health $l_pool)"

	if [ "$pool_health" = ONLINE ] ;then
	
		echo "[INFO2] SRC ($l_pool) pool state is ONLINE , return 0" 1>&4

	elif [ "$pool_health" = DEGRADED ] ;then

		echo "[ERROR] SRC ($l_pool) pool state is DEGRADED , exit 1" 1>&3
		exit 1
	
	elif [ "$pool_health" = SUSPENDED ] ;then

		echo "[ERROR] SRC ($l_pool) pool state is SUSPENDED , exit 1" 1>&3
		exit 1
		
	elif [ "$pool_health" = UNAVAIL ] ;then

		echo "[ERROR] SRC ($l_pool) pool state is UNAVAIL , exit 1" 1>&3
		exit 1
		
	fi

done

for l_pool in $d_pool ;do

	[ "$s_type" = sp ] && return 0

	local pool_health="$($d_srv $zpool list -H -o health $l_pool)"

	if [ "$pool_health" = ONLINE ] ;then
	
		echo "[INFO2] DEST ($l_pool) pool state is ONLINE , return 0" 1>&4

	elif [ "$pool_health" = DEGRADED ] ;then

		echo "[ERROR] DEST ($l_pool) pool state is DEGRADED , exit 1" 1>&3
		exit 1
		
	elif [ "$pool_health" = SUSPENDED ] ;then

		echo "[ERROR] DEST ($l_pool) pool state is SUSPENDED , exit 1" 1>&3
		exit 1
		
	elif [ "$pool_health" = UNAVAIL ] ;then

		echo "[ERROR] DEST ($l_pool) pool state is UNAVAIL exit , 1" 1>&3
		exit 1
		
	fi

done

return 0

}

do_pool_check2() {
printf "\n---------------------------------- do_pool_check2 --------------------------------\n" 1>&4
			# tested (once)
			
for i in s d ;do

	[ "$i" = d ] && [ "$s_type" = sp ] && return 0

	local l_srv=${i}_srv
	local l_pool=${i}_pool

	[ "$i" = "s" ] && local which=SRC
	[ "$i" = "d" ] && local which=DEST
	
	local pool_health="$(${!l_srv} $zpool list -H -o health ${!l_pool})"

	if [ "$pool_health" = ONLINE ] ;then
	
		echo "[INFO2] $which (${!l_pool}) pool state is ONLINE , return 0" 1>&4
		continue
		
	elif [ "$pool_health" = DEGRADED ] ;then

		echo "[ERROR] $which (${!l_pool}) pool state is DEGRADED , exit 1" 1>&3
		exit 1
	
	elif [ "$pool_health" = SUSPENDED ] ;then

		echo "[ERROR] $which (${!l_pool}) pool state is SUSPENDED exit 1" 1>&3
		exit 1
	
	elif [ "$pool_health" = UNAVAIL ] ;then

		echo "[ERROR] $which (${!l_pool}) pool state is UNAVAIL , exit 1" 1>&3
		exit 1
	
	fi

done

return 0

}



