#!/bin/bash


# reset test src and dest pools ( after tests. to start fresh )


cfg1=../config-local/type1.cfg
cfg2=../config-local/type2.cfg



do_main () {

for cfg in {$cfg1,$cfg2} ;do

		printf "\n=================================== $cfg =================================== \n"


							(source $cfg; do_destroy_src_pool_snap)
							(source $cfg; do_destroy_src_snaps)
							(source $cfg; do_destroy_dest_path)

done

}



do_destroy_src_pool_snap () {
printf "\n--------------------------------------( do_destroy_src_pool_snap )------------------------------ \n\n"

for child in $($s_zfs get -t snapshot -s local -H -o name $pfix:stype:p $s_pool) ;do

		echo "zfs destroy $child"
		$s_zfs destroy $child

done

}



do_destroy_src_snaps() {
printf "\n--------------------------------------( do_destroy_src_snaps )---------------------------------- \n\n"

local lsets

if [ -z "$s_sets" ] ;then
	lsets="$s_pool"
else
	for set in $s_sets ;do		#(!double quoting expands as single word)
		lsets+="$s_pool/$set "
	done
fi


for lset in $lsets ; do

	for child in $($s_zfs get -t snapshot -s local -H -o name -r $pfix:stype:p $lset) ;do

		echo "zfs destroy $child"
		$s_zfs destroy $child

	done

	for child in $($s_zfs get -t snapshot -s local -H -o name -r $pfix:snum $lset) ;do

		echo "zfs destroy $child"
		$s_zfs destroy $child

	done

done

}



do_destroy_dest_path() {
printf "\n--------------------------------------( do_destroy_dest_path )---------------------------------- \n\n"

		$d_zfs list -H -o name $d_path > /dev/null 2>&1
		if [ $? = 0 ] ; then
	 		echo "zfs destroy $d_path"
			$d_zfs destroy -r $d_path
		fi
}



do_main



printf  "\nthis script ran for  $SECONDS sec\n"


