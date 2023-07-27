#!/bin/bash


# reset test src and dest pools ( after tests. to start fresh )


cfg1=../config/type1.cfg
cfg2=../config/type2.cfg


do_main () {

	for cfg in {$cfg1,$cfg2} ;do

		source $cfg

		printf "\n================================== $cfg ================================== \n"


							do_destroy_src_pool_snap
							do_destroy_src_snaps
							do_destroy_dest_path

	done
}



do_destroy_src_pool_snap () {
printf "\n ------------------------------- do_destroy_src_pool_snap ------------------------------- \n\n"

		$s_zfs list -H -o name $s_pool@$pfix-parent > /dev/null 2>&1
		if [ $? = 0 ] ; then
			echo "zfs destroy $s_pool@$pfix-parent"
			$s_zfs destroy $s_pool@$pfix-parent
		fi
}



do_destroy_src_snaps() {
printf "\n ------------------------------- do_destroy_src_snaps ------------------------------- \n\n"

	for set in $s_sets ;do
		for child in $($s_zfs list -t snapshot -r -H -o name $s_pool/$set | grep $pfix) ;do

			echo "zfs destroy $child"
			$s_zfs destroy $child

		done
	done
}



do_destroy_dest_path() {
printf "\n ------------------------------- do_destroy_dst_path ------------------------------- \n\n"

		$d_zfs list -H -o name $d_path > /dev/null 2>&1
		if [ $? = 0 ] ; then
	 		echo "zfs destroy $d_zfs destroy $d_path"
			$d_zfs destroy -r $d_path
		fi
}



do_main

printf  "\nthis script ran for  $SECONDS sec\n"

