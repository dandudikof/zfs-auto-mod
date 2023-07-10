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
	
		echo "[INFO2] SRC ($l_pool) pool state is $pool_health" 1>&4

	else 

		echo "[ERROR] SRC ($l_pool) pool state is $pool_health" 1>&3
		exit 1
	
	fi

done

for l_pool in $d_pool ;do

	[ "$1" = s ] && return 0

	local pool_health="$($d_srv $zpool list -H -o health $l_pool)"

	if [ "$pool_health" = ONLINE ] ;then
	
		echo "[INFO2] DEST ($l_pool) pool state is $pool_health" 1>&4

	else 

		echo "[ERROR] DEST ($l_pool) pool state is $pool_health" 1>&3
		exit 1
	
	fi

done

return 0

}

do_pool_check2() {
printf "\n---------------------------------- do_pool_check2 --------------------------------\n" 1>&4
			# tested (once)
			
for i in s d ;do

	[ "$i" = d ] && [ "$1" = s ] && return 0

	local l_srv=${i}_srv
	local l_pool=${i}_pool

	[ "$i" = "s" ] && local which=SRC
	[ "$i" = "d" ] && local which=DEST
	
	local pool_health="$(${!l_srv} $zpool list -H -o health ${!l_pool})"

	if [ "$pool_health" = ONLINE ] ;then
	
		echo "[INFO2] $which (${!l_pool}) pool state is $pool_health" 1>&4
		continue
		
	else 

		echo "[ERROR] $which (${!l_pool}) pool state is $pool_health" 1>&3
		exit 1
	
	fi

done

return 0

}



