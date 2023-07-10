#
#	if do_remote_check fails exit with 1 and stops script, else returns 0 and continues
#
#	for testing use $script_dir/utilities/etherwake.sh (fake). as $wake_cmd in config
#



do_remote_check() {
printf "\n--------------------------------------( do_remote_check )---------------------------------------\n" 1>&4

[ -z "${s_srv}" ] && echo "[info2] s_srv server set as local ($(hostname))" 1>&4
[ -n "${s_srv}" ] && echo "[info2] s_srv server set as remote ($s_ip)" 1>&4
[ -z "${d_srv}" ] && echo "[info2] d_srv server set as local ($(hostname))" 1>&4
[ -n "${d_srv}" ] && echo "[info2] d_srv server set as remote ($d_ip)" 1>&4

for sord in s d ;do

	local l_srv=${sord}_srv
	local l_ip=${sord}_ip

	[ "$sord" = "d" ] && [ "$1" = "s" ] && return 0

	if [ -n "${!l_srv}" ] ;then

		do_wake_and_ping $sord
		local ret="$?"

		if [ "$ret" = "2" ] ;then
			echo "[info2] $l_srv server was reached at (${!l_ip}) on first try" 1>&4
		elif [ "$ret" = "3" ] ;then
			echo "[info2] $l_srv server was reached at (${!l_ip}) after ($tcount) tries" 1>&4
			sleep 10
		else
			echo "[ERROR] $l_srv server NOT reached at (${!l_ip}) after ($tcount) tries " 1>&3
			exit 1
		fi

	fi

done

return 0

}



do_wake_and_ping(){
#printf "\n--------------------------------------( wake_and_ping )-----------------------------------------\n" 1>&4

local l_mac=${1}_mac
local l_ip=${1}_ip

tcount=1

ping -c1 -W1 "${!l_ip}" > /dev/null 2>&1
[ "$?" = 0 ] &&	return 2

if [ -n "$wake_cmd" ] && [ -n "${!l_mac}" ] ;then

	echo "[info2] doing ($wake_cmd ${!l_mac})" 1>&4
	"$wake_cmd" "${!l_mac}"

fi

while [ "$tcount" -le 10 ] ;do

	sleep 60
	ping -c1 -W1 "${!l_ip}" > /dev/null 2>&1
	[ $? = 0 ] && return 3

	echo "[DEBUG] ping_check to (${!l_ip}) ret=($ret) count=($tcount) , sleep 60" 1>&5

	((tcount++))

done

return 1

}



