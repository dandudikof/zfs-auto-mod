#
#	if do_pool_check fails it exits with 1 and stops script, else returns 0 and continues
#





do_pool_check1() {
printf "\n---------------------------------- do_pool_check1 --------------------------------\n" 1>&4
			# untested
			
local l_pool

for l_pool in $s_pool ;do

	grep_state="$($s_srv $zpool status $l_pool | grep 'state:')"

	if [ $(echo "$state" | grep 'ONLINE' > /dev/null 2>&1 )$? ] ;then
	
		echo "[INFO2] SRC ($l_pool) pool state is ONLINE , return 0" 1>&4

	elif [ $(echo "$state" | grep 'DEGRADED' > /dev/null 2>&1 )$? ] ;then

		echo "[ERROR] SRC ($l_pool) pool state is DEGRADED , exit 1" 1>&3
		exit 1
		
	elif [ $(echo "$state" | grep 'SUSPENDED' > /dev/null 2>&1 )$? ] ;then

		echo "[ERROR] SRC ($l_pool) pool state is SUSPENDED , exit 1" 1>&3
		exit 1
		
	elif [ $(echo "$state" | grep 'UNAVAIL' > /dev/null 2>&1 )$? ] ;then

		echo "[ERROR] SRC ($l_pool) pool state is UNAVAIL , exit 1" 1>&3
		exit 1
		
	fi

done

for l_pool in $d_pool ;do

	grep_state="$($d_srv $zpool status $l_pool | grep 'state:')"

	if [ $(echo "$state" | grep 'ONLINE' > /dev/null 2>&1 )$? ] ;then
	
		echo "[INFO2] DEST ($l_pool) pool state is ONLINE , exit 0" 1>&4

	elif [ $(echo "$state" | grep 'DEGRADED' > /dev/null 2>&1 )$? ] ;then

		echo "[ERROR] DEST ($l_pool) pool state is DEGRADED , exit 1" 1>&3
		exit 1
		
	elif [ $(echo "$state" | grep 'SUSPENDED' > /dev/null 2>&1 )$? ] ;then

		echo "[ERROR] DEST ($l_pool) pool state is SUSPENDED , exit 1" 1>&3
		exit 1
		
	elif [ $(echo "$state" | grep 'UNAVAIL' > /dev/null 2>&1 )$? ] ;then

		echo "[ERROR] DEST ($l_pool) pool state is UNAVAIL , exit 1" 1>&3
		exit 1
	
	fi

done

return 0

}

do_pool_check2() {
printf "\n---------------------------------- do_pool_check2 --------------------------------\n" 1>&4
			# untested

for i in s d ;do

	local l_srv=${i}_srv
	local l_pool=${i}_pool

	[ "$i" = "s" ] &&  local which=SRC
	[ "$i" = "d" ] &&  local which=DEST

	grep_state="$(${!l_srv} $zpool status ${!l_pool} | grep 'state:')"

	if [ $(echo "$state" | grep 'ONLINE' > /dev/null 2>&1 )$? ] ;then
	
		echo "[INFO2] $which (${!l_pool}) pool state is ONLINE , return 0" 1>&3
		continue
		
	elif [ $(echo "$state" | grep 'DEGRADED' > /dev/null 2>&1 )$? ] ;then

		echo "[ERROR] $which (${!l_pool}) pool state is DEGRADED , exit 1" 1>&3
		exit 1
		
	elif [ $(echo "$state" | grep 'SUSPENDED' > /dev/null 2>&1 )$? ] ;then

		echo "[ERROR] $which (${!l_pool}) pool state is SUSPENDED , exit 1" 1>&3
		exit 1
		
	elif [ $(echo "$state" | grep 'UNAVAIL' > /dev/null 2>&1 )$? ] ;then

		echo "[ERROR] $which (${!l_pool}) pool state is UNAVAIL , exit 1" 1>&3
		exit 1
		
	fi

done

return 0

}



