#!/bin/bash 
#
# implement on receiving server in root chrontab

if [ "$(cat /tmp/shutdown)" = "1" ] ;then

	echo "0" > "/tmp/shutdown"
	echo "$(date +%x-%X) doing shutdown" >> /var/log/shutdown.log
	shutdown -h now
fi

exit 0