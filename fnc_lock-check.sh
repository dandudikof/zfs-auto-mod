#
# checks for existence of lockfile for execution of current script with current *.cfg file
# exits with 1 if lockfile exist and pid that created it is still running
# else removes stale lock files, creates new lock files, returns 0 and continues
#



lock_dir="/var/run/lock/zfs-auto-mod"

pid=$$
script="$(basename $0)"
config_file="$(basename $1)"
config_path="$(readlink -f $1)"
lock_file="$lock_dir/$script/$config_file.lock"
pid_file="$lock_dir/$script/$config_file.pid"

[ ! -d "$lock_dir/$script" ] && mkdir -p "$lock_dir/$script"



do_lock_check() {
printf "\n--------------------------------------( do_lock_check )-----------------------------------------\n" 1>&4
			# tested outside of scripts


if [ -f $lock_file ] ;then
	
	local config_pid="$(cat $pid_file)"
	local config_pid_comm="$(ps -p $config_pid -o comm=)"
		
	ps -p "$config_pid" > /dev/null 2>&1
	if [ "$?" = 0 ] && [ "$config_pid_comm" = "$script" ] ;then
	
		echo "[ERROR] lock files exist for $script $config_file and script is running , exit 1" 1>&3
		exit 1
		
	else
	
		echo "[info2] lock files exist for $script $config_file but are stale , removing" 1>&4
		rm "$lock_file"
		rm "$pid_file"
	
	fi

fi

echo "[info2] creating lock_file for $script $config_file" 1>&4
echo "[info2] creating pid_file for $script $config_file" 1>&4
echo "$config_path" > "$lock_file"
echo "$pid" > "$pid_file"

return 0

}



do_lock_clear() {
printf "\n--------------------------------------( do_lock_clear )-----------------------------------------\n" 1>&4



if [ -f $lock_file ] ;then
	
		echo "[info2] removing lock_file for $script $config" 1>&4
		echo "[info2] removing pid_file for $script $config" 1>&4
		rm "$lock_file"
		rm "$pid_file"
fi

return 0

}



