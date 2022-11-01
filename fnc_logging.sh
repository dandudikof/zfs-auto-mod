#
#
#
#	assigments of logging channels
# 1 = stdout	= exec		1>		>(stdoutlog)		# [STDOUT]
# 2 = stderr	= exec		2>		>(sterrlog)			# [STDERR]
# 3 = info1 	= exec		3>>		$log3				# [INFO1]
# 4 = info2 	= exec		4>>		$log3				# [INFO2]
# 5 = debug 	= exec		5>>		$log3				# [DEBUG]
# 6 = send  	= exec		6>>		>(sendlog)			# [SEND-1]
# 7 = send  	= exec		7>>		$log6				# formating for zfs send
# 8 = recv  	= exec		8>>		>(recvlog)			# [RECV-1]
# 9 = recv  	= exec		9>>		$log3				# formating for zfs recv


log3="$logdir/$log_file3"
log6="$logdir/$log_file6"

[ ! -d "$logdir" ] && mkdir -p "$logdir"
[ ! -f "$log3" ] &&	touch "$log3"
[ ! -f "$log6" ] &&	touch "$log6"




#1
stdoutlog () {

		while read line ;do
			echo "[STDOUT] $line" >> $log3
		done

}



#2
stderrlog () {

		while read line ;do
			echo "[STDERR] $line" >> $log3
		done

}



#6 incrementaly skips more send progress lines simple version 1
sendlog1 () {

		local lcount=0 		#line count before print , then reset, and repeat
		local tcount=0		#total line count with numbers , for sorting cond

		while read line ;do
		
			#majority of send lines with time upfront that we want to prune
			if [ -n "$(echo $line | grep ^[0-9][0-9]:)" ] ; then

				((lcount++))
				((tcount++))

				#echo "lcount=($lcount) tcount=($tcount)" 1>&5 # for debugging

				if  [ "$tcount" -le 10 ] ;then
					echo "[SEND-1] $line" >> $log6
					lcount=0
				elif [ "$tcount" -le 100 ] && [ "$lcount" -eq 5 ] ;then
					echo "[SEND-1] $line" >> $log6
					lcount=0
				elif [ "$tcount" -gt 100 ] && [ "$lcount" -eq 10 ] ;then
					echo "[SEND-1] $line" >> $log6
					lcount=0
				fi

				[ "$tcount" -eq 10 ] && echo "[SEND-1] print every 5-th line" >> $log6
				[ "$tcount" -eq 100 ] && echo "[SEND-1] print every 10-th line" >> $log6

			#minority of send info lines we want to keep
			else

				lcount=0
				tcount=0

				if [ -n "$(echo $line | grep ^'send from')" ] ; then
					echo "[SEND-1] $line " | sed 's! to ! >>>\n[SEND>1] to !g' >> $log6
				else
					echo "[SEND-1] $line"  >> $log6
				fi
			fi

		done

}



#6 incrementaly skips more send progress lines version 2 (unfinished)
sendlog2 () {

		local lcount=0		#line count before print , then reset, and repeat
		local lskip=1		#increments the nth line to print
		local count=0		#counts printed lines before incrementing skip

		while read line ;do

			#majority of send lines with time upfront that we want to prune
			if [ -n "$(echo $line | grep ^[0-9][0-9]:)" ] ; then

				((lcount++))

				#echo "lcount=($lcount) skip=($skip) count=($count)" 1>&3 # for debugging

				if  [ "$lcount" -eq "$lskip"  ] ;then

					echo "[SEND-2] $line" >> $log6
					((count++))
					lcount=0

						if [ "$count" -ge 5 ] ;then
							((skip++))
							count=0
							echo "[SEND-2] switching to print every $lskip(d-th) line" >> $log6
						fi

				fi

			#minority of send info lines we want to keep
			else
				echo "[SEND-2] $line"  >> $log6
				lcount=0
				skip=1
			fi

		done

}



#8 adds [RECV-1] to each line and splits up long recv lines in two
recvlog () {

		while read line ;do

			if [ -n "$(echo $line | grep ^received)" ] ; then
				echo "[RECV-1] $line" >> $log3
			else
				echo "[RECV-1] $line " | sed 's! into ! >>>\n[RECV>1] >>>>>>>   into   !g' >> $log3
			fi

		done

}



exec 1> >(stdoutlog)
exec 2> >(stderrlog)


#verbose and debug
if [ "$verbose" = 1 ] ;then
	exec 3>> $log3
	exec 4> /dev/null
	exec 5> /dev/null
elif [ "$verbose" = 2 ] ;then
	exec 3>> $log3
	exec 4>> $log3
	exec 5> /dev/null
elif [ "$verbose" = 3 ] ;then
	exec 3>> $log3
	exec 4>> $log3
	exec 5>> $log3
else
	exec 3> /dev/null
	exec 4> /dev/null
	exec 5> /dev/null
fi

# send logging
exec 6> >(sendlog1)
exec 7>> $log6

# recv logging
if [ "$verbrecv" = 1 ]  ;then
	exec 8> >(recvlog)
	exec 9>> $log3
else
	exec 8> /dev/null
	exec 9> /dev/null
fi


