#
#	if do_remote_check fails it exits with 1 and stops script, else returns 0 and continues
#
#	for testing use $script_dir/utilities/etherwake.sh (fake). as $wake_cmd in config
#



do_remote_check1() {
printf "\n---------------------------------- do_remote_check1 --------------------------------\n" 1>&4

if [ -z "$s_srv" ]  ;then
	echo "[INFO2] s_srv was set to (), do_everything localy" 1>&4
else

	do_wake_and_ping1 s
	
	if [ "$isup" = "y" ] ; then
		echo "[INFO2] SRC server was reached at ($s_ip) , on first try, continue" 1>&4
	elif [ "$isup" = "yy" ] ; then
		echo "[INFO2] SRC server was reached at ($s_ip) sleep for 10, continue " 1>&4
		sleep 10
	else
		echo "[ERROR] SRC server could not be reached at ($s_ip) after ($tcount) tries , exit 1" 1>&3
		exit 1
	fi
fi

if [ -z "$d_srv" ]  ;then
	echo "[INFO2] d_srv was set to (), do_everything localy" 1>&4
else

	do_wake_and_ping1 d
	
	if [ "$isup" = "y" ] ; then
		echo "[INFO2] DEST server was reached at ($d_ip) , on first try, continue" 1>&4		
	elif [ "$isup" = "yy" ] ; then
		echo "[INFO2] DEST server was reached at ($d_ip) sleep for 10, continue" 1>&4
		sleep 10
	else
		echo "[ERROR] DEST server could not be reached at ($d_ip) after ($tcount) tries , exit 1" 1>&3
		exit 1
	fi

fi

return 0

}

do_remote_check2() {
printf "\n---------------------------------- do_remote_check2 --------------------------------\n" 1>&4

for sord in s d ;do

	local l_srv=${sord}_srv
	local l_ip=${sord}_ip
	[ "$sord" = "s" ] && local which=SRC
	[ "$sord" = "d" ] && local which=DEST

	if [ -z "${!l_srv}" ] ; then
		echo "[INFO2] "$sord"_srv was set to () not exiting, and continue localy" 1>&4
	else

		do_wake_and_ping2 $sord
		
		if [ "$isup" = "y" ] ; then
			echo "[INFO2] $which server was reached at (${!l_ip}) on first try,continue" 1>&4
		elif [ "$isup" = "yy" ] ; then
			echo "[INFO2] $which server was reached at (${!l_ip}) sleep for 10, continue" 1>&4
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
printf "\n---------------------------------- wake_and_ping_check1 ----------------------------------\n" 1>&4

	if [ "$1" = "s" ] ;then
		local l_mac=$s_mac 
		local l_ip=$s_ip
	elif [ "$1" = "d" ] ;then
		local l_mac=$d_mac
		local l_ip=$d_ip
	fi
	
local ret=""
tcount=1
isup=""

ping -c1 -W1 "$l_ip" > /dev/null 2>&1
if [ "$?" = 0 ] ; then
	isup=y
	return 0
fi

echo "[INFO2] doing ($wake_cmd $l_mac)" 1>&4

[ -n "$wake_cmd" ] && [ -n "${l_mac}" ] && "$wake_cmd" "$l_mac"

while  [ "$ret" != 0 ] && [ "$tcount" -le 10 ] ; do

	sleep 30
	ping -c1 -W1 "$l_ip" > /dev/null 2>&1
	ret=$?

	if [ "$ret" = 0 ] ;then
		isup=yy
		return 0
	fi
	
	echo "[DEBUG] ping_check to ($l_ip) ret=($ret) count=($tcount) , sleep 30" 1>&5
	
	((tcount++))

done

return 1

}



do_wake_and_ping2(){
printf "\n---------------------------------- wake_and_ping_check2 ----------------------------------\n" 1>&4


local l_mac=${1}_mac
local l_ip=${1}_ip

local ret=""
tcount=1
isup=""

ping -c1 -W1 "${!l_ip}" > /dev/null 2>&1
if [ "$?" = 0 ] ; then
	isup=y
	return 0
fi

echo "[INFO2] doing ($wake_cmd ${!l_mac})" 1>&4

[ -n "$wake_cmd" ] && [ -n "${!l_mac}" ] && "$wake_cmd" "${!l_mac}"

while  [ "$ret" != 0 ] && [ "$tcount" -le 10 ] ; do

	sleep 30
	ping -c1 -W1 "${!l_ip}" > /dev/null 2>&1
	ret=$?

	if [ "$ret" = 0 ] ;then
		isup=yy
		return 0
	fi
	
	echo "[DEBUG] ping_check to (${!l_ip}) ret=($ret) count=($tcount) , sleep 30" 1>&5
	
	((tcount++))

done

return 1

}



