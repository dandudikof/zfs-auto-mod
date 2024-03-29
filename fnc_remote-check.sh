#
#	if do_remote_check fails it exits with 1 and stops script, else returns 0 and continues
#
#	for testing use $script_dir/utilities/etherwake.sh (fake). as $wake_cmd in config
#



do_remote_check1() {
printf "\n--------------------------------------( do_remote_check1 )--------------------------------------\n" 1>&4

if [ -z "$s_srv" ]  ;then
	echo "[info2] s_srv was set to (), do_everything localy" 1>&4
else

	do_wake_and_ping1 s
	local ret="$?"
	
	if [ "$ret" = "2" ] ; then
		echo "[info2] SRC server was reached at ($s_ip) , on first try, continue" 1>&4
	elif [ "$ret" = "3" ] ; then
		echo "[info2] SRC server was reached at ($s_ip) sleep for 10, continue " 1>&4
		sleep 10
	else
		echo "[ERROR] SRC server could not be reached at ($s_ip) after ($tcount) tries" 1>&3
		exit 1
	fi
fi

[ "$1" = s ] && return 0

if [ -z "$d_srv" ]  ;then
	echo "[info2] d_srv was set to (), do_everything localy" 1>&4
else

	do_wake_and_ping1 d
	local ret="$?"

	if [ "$ret" = "2" ] ; then
		echo "[info2] DEST server was reached at ($d_ip) , on first try, continue" 1>&4		
	elif [ "$ret" = "3" ] ; then
		echo "[info2] DEST server was reached at ($d_ip) sleep for 10, continue" 1>&4
		sleep 10
	else
		echo "[ERROR] DEST server could not be reached at ($d_ip) after ($tcount) tries" 1>&3
		exit 1
	fi

fi

return 0

}

do_remote_check2() {
printf "\n--------------------------------------( do_remote_check2 )--------------------------------------\n" 1>&4

for sord in s d ;do

	local l_srv=${sord}_srv
	local l_ip=${sord}_ip
	[ "$sord" = "s" ] && local which=SRC
	[ "$sord" = "d" ] && local which=DEST

	[ "$sord" = "d" ] && [ "$1" = "s" ] && return 0

	if [ -z "${!l_srv}" ] ; then
		echo "[info2] "$sord"_srv was set to () not exiting, and continue localy" 1>&4
	else

		do_wake_and_ping2 $sord
		local ret="$?"

		if [ "$ret" = "2" ] ; then
			echo "[info2] $which server was reached at (${!l_ip}) on first try,continue" 1>&4
		elif [ "$ret" = "3" ] ; then
			echo "[info2] $which server was reached at (${!l_ip}) sleep for 10, continue" 1>&4
			sleep 10
		else
			echo "[ERROR] $which server could not be reached at (${!l_ip}) after ($tcount) tries " 1>&3
			exit 1
		fi
	fi

done

return 0

}

do_wake_and_ping1(){
printf "\n--------------------------------------( wake_and_ping_check1 )----------------------------------\n" 1>&4

	if [ "$1" = "s" ] ;then
		local l_mac=$s_mac 
		local l_ip=$s_ip
	elif [ "$1" = "d" ] ;then
		local l_mac=$d_mac
		local l_ip=$d_ip
	fi

tcount=1

ping -c1 -W1 "$l_ip" > /dev/null 2>&1
[ "$?" = 0 ] &&	return 2

echo "[info2] doing ($wake_cmd $l_mac)" 1>&4

[ -n "$wake_cmd" ] && [ -n "${l_mac}" ] && "$wake_cmd" "$l_mac"

while  [ "$tcount" -le 10 ] ; do

	sleep 30
	ping -c1 -W1 "$l_ip" > /dev/null 2>&1
	[ $? = 0 ] && return 3
	
	echo "[DEBUG] ping_check to ($l_ip) ret=($ret) count=($tcount) , sleep 30" 1>&5
	
	((tcount++))

done

return 1

}



do_wake_and_ping2(){
printf "\n--------------------------------------( wake_and_ping_check2 )----------------------------------\n" 1>&4


local l_mac=${1}_mac
local l_ip=${1}_ip

tcount=1

ping -c1 -W1 "${!l_ip}" > /dev/null 2>&1
[ "$?" = 0 ] &&	return 2

echo "[info2] doing ($wake_cmd ${!l_mac})" 1>&4

[ -n "$wake_cmd" ] && [ -n "${!l_mac}" ] && "$wake_cmd" "${!l_mac}"

while [ "$tcount" -le 10 ] ; do

	sleep 30
	ping -c1 -W1 "${!l_ip}" > /dev/null 2>&1
	[ $? = 0 ] && return 3
	
	echo "[DEBUG] ping_check to (${!l_ip}) ret=($ret) count=($tcount) , sleep 30" 1>&5
	
	((tcount++))

done

return 1

}



