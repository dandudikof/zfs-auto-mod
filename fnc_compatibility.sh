# freebsd compatibility functions

if [ "$(uname)" = "FreeBSD" ] ;then 

	pkg info coreutils > /dev/null 2>&1
	if [ "$?" = 1 ] ;then

		echo "[ERROR] GNU coreutils is missing, unable to run script" >> $log_file3
		echo "[ERROR] please install GNU coreutils (pkg install coreutils)" >> $log_file3
		exit 1

	else

		tac() { gtac "$@"; }
		tail() { gtail "$@"; }
		head() { ghead "$@"; }

	fi

fi