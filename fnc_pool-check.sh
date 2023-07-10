#
#	if do_pool_check fails it exits with 1 and stops script, else returns 0 and continues
#



do_pool_check() {
printf "\n--------------------------------------( do_pool_check )-----------------------------------------\n" 1>&4

for i in s d ;do

	[ "$i" = d ] && [ "$1" = s ] && return 0

	local l_srv=${i}_srv
	local l_pool=${i}_pool

	local pool_health="$(${!l_srv} $zpool list -H -o health ${!l_pool})"

	if [ "$pool_health" = ONLINE ] ;then
	
		echo "[info2] $l_pool pool (${!l_pool}) state is ($pool_health)" 1>&4
		continue
		
	else 

		echo "[ERROR] $l_pool pool (${!l_pool}) state is ($pool_health)" 1>&3
		exit 1
	
	fi

done

return 0

}



