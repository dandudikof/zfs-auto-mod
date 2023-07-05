


do_sort_list1() {

printf "\n---------------------------------- do_sort_list1 -----------------------------------\n" 1>&5
		# auto dataset sort (uncludes all under s_pool,s_sets and parent,container,dataset unless excluded)

do_declare_arrays

if [ -z "$s_sets" ] ;then
	lsets="$s_pool"
else
	for set in $s_sets ;do		#(!double quoting expands as single word)
		lsets+="$s_pool/$set "
		#lsets="$lsets $s_pool/$set"
	done
fi

include_i_array+=($s_pool)
parent_i_array+=($s_pool)
include_a_array+=([$s_pool]=p)

[ "$strip_pool"  = 1 ] && dest_a_array+=([$s_pool]="$d_path")
[ "$strip_pool" != 1 ] && dest_a_array+=([$s_pool]="$d_path/$s_pool")

for lset in $lsets ; do
	for src_child in $($s_zfs list -Hr -o name $lset) ;do

		[ "$src_child" = "$s_pool" ] && continue

		[ "$strip_pool"  = 1 ] && dest_child="$d_path/${src_child#${s_pool}/}"
		[ "$strip_pool" != 1 ] && dest_child="$d_path/$src_child"

		local lret="$($s_zfs get $pfix:incl -s local,received -H -o value $src_child)"
		local iret="$($s_zfs get $pfix:incl -s inherited -H -o value $src_child)"
		local excl="$($s_zfs get $pfix:excl -s local,inherited,received -H -o value $src_child)"
		local clone="$($s_zfs get origin -t filesystem,volume -H -o value $src_child)"
		
		[ "$src_child" = "$lset" ] && [ -z "$lret" ] && lret=d
		[ "$clone" = "-" ] && unset clone

		if [ "$excl" = "1" ] ;then

					exclude_i_array+=($src_child)
					#echo "[SORT] classified as excluded ($src_child)"
		
		elif [ "$lret" = "p" ] ;then

					include_i_array+=($src_child)
					parent_i_array+=($src_child)
					include_a_array+=([$src_child]=p)
					dest_a_array+=([$src_child]="$dest_child")
					#echo "[SORT] classified as parent ($src_child)"

		elif [ "$lret" = "c" ] ;then

					include_i_array+=($src_child)
					container_i_array+=($src_child)
					include_a_array+=([$src_child]=c)
					dest_a_array+=([$src_child]="$dest_child")
					#echo "[SORT] classified as container ($src_child)"

		else

					include_i_array+=($src_child)
					dataset_i_array+=($src_child)
					[ "$clone" ] || include_a_array+=([$src_child]=d)
					[ "$clone" ] && include_a_array+=([$src_child]=cl)
					[ "$clone" ] && clone_i_array+=($src_child)
					[ "$clone" ] && clone_a_array+=([$src_child]="$clone")
					dest_a_array+=([$src_child]="$dest_child")
					#echo "[SORT] classified as else-dataset ($src_child)"

		fi

	done

done

do_verblist

}



do_sort_list2() {
printf "\n---------------------------------- do_sort_list2 -----------------------------------\n" 1>&5
		# auto parent sort (uncludes all under s_pool,s_sets and parent,container,dataset unless excluded)

do_declare_arrays

if [ -z "$s_sets" ] ;then
	lsets="$s_pool"
else
	for set in $s_sets ;do		#(!double quoting expands as single word)
		lsets+="$s_pool/$set "
		#lsets="$lsets $s_pool/$set"
	done
fi

include_i_array+=($s_pool)
parent_i_array+=($s_pool)
include_a_array+=([$s_pool]=p)

[ "$strip_pool"  = 1 ] && dest_a_array+=([$s_pool]="$d_path")
[ "$strip_pool" != 1 ] && dest_a_array+=([$s_pool]="$d_path/$s_pool")

for lset in $lsets ; do
	for src_child in $($s_zfs list -Hr -o name $lset) ;do

		[ "$src_child" = "$s_pool" ] && continue

		[ "$strip_pool"  = 1 ] && dest_child="$d_path/${src_child#${s_pool}/}"
		[ "$strip_pool" != 1 ] && dest_child="$d_path/$src_child"

		local lret="$($s_zfs get $pfix:incl -s local,received -H -o value $src_child)"
		local iret="$($s_zfs get $pfix:incl -s inherited -H -o value $src_child)"
		local excl="$($s_zfs get $pfix:excl -s local,inherited,received -H -o value $src_child)"
		local clone="$($s_zfs get origin -t filesystem,volume -H -o value $src_child)"

		[ "$src_child" = "$lset" ] && [ -z "$lret" ] && lret=p
		[ "$clone" = "-" ] && unset clone

		if [ "$excl" = "1" ] ;then

					exclude_i_array+=($src_child)
					#echo "[SORT] classified as excluded ($src_child)"
		
		elif [ "$lret" = "p" ] ;then

					include_i_array+=($src_child)
					parent_i_array+=($src_child)
					include_a_array+=([$src_child]=p)
					dest_a_array+=([$src_child]="$dest_child")
					#echo "[SORT] classified as parent ($src_child)"

		elif [ "$lret" = "c" ] ;then

					include_i_array+=($src_child)
					container_i_array+=($src_child)
					include_a_array+=([$src_child]=c)
					dest_a_array+=([$src_child]="$dest_child")
					#echo "[SORT] classified as container ($src_child)"

		else

					include_i_array+=($src_child)
					dataset_i_array+=($src_child)
					[ "$clone" ] || include_a_array+=([$src_child]=d)
					[ "$clone" ] && include_a_array+=([$src_child]=cl)
					[ "$clone" ] && clone_i_array+=($src_child)
					[ "$clone" ] && clone_a_array+=([$src_child]="$clone")
					dest_a_array+=([$src_child]="$dest_child")
					#echo "[SORT] classified as else-dataset ($src_child)"

		fi

	done

done

do_verblist

}



do_sort_list3() {
printf "\n---------------------------------- do_sort_list3 -----------------------------------\n" 1>&5
		# manual sort (must set every parent,container,dataset otherwise exclude)

do_declare_arrays

if [ -z "$s_sets" ] ;then
	lsets="$s_pool"
else
	for set in $s_sets ;do		#(!double quoting expands as single word)
		lsets+="$s_pool/$set "
		#lsets="$lsets $s_pool/$set"
	done
fi

include_i_array+=($s_pool)
parent_i_array+=($s_pool)
include_a_array+=([$s_pool]=p)

[ "$strip_pool"  = 1 ] && dest_a_array+=([$s_pool]="$d_path")
[ "$strip_pool" != 1 ] && dest_a_array+=([$s_pool]="$d_path/$s_pool")

for lset in $lsets ; do
	for src_child in $($s_zfs list -Hr -o name $lset) ;do

		[ "$src_child" = "$s_pool" ] && continue

		[ "$strip_pool"  = 1 ] && dest_child="$d_path/${src_child#${s_pool}/}"
		[ "$strip_pool" != 1 ] && dest_child="$d_path/$src_child"

		local lret="$($s_zfs get $pfix:incl -s local,received -H -o value $src_child)"
		local excl="$($s_zfs get $pfix:excl -s local,inherited,received -H -o value $src_child)"
		local clone="$($s_zfs get origin -t filesystem,volume -H -o value $src_child)"


		[ "$excl" = 1 ] && unset lret
		[ "$clone" = "-" ] && unset clone

		case "$lret" in

			p)
						include_i_array+=($src_child)
						parent_i_array+=($src_child)
						include_a_array+=([$src_child]=p)
						dest_a_array+=([$src_child]="$dest_child")
						#echo "[SORT] classified as parent ($src_child)"
			;;

			c)
						include_i_array+=($src_child)
						container_i_array+=($src_child)
						include_a_array+=([$src_child]=c)
						dest_a_array+=([$src_child]="$dest_child")
						#echo "[SORT] classified as container ($src_child)"
			;;

			d)
						include_i_array+=($src_child)
						dataset_i_array+=($src_child)
						[ "$clone" ] || include_a_array+=([$src_child]=d)
						[ "$clone" ] && include_a_array+=([$src_child]=cl)
						[ "$clone" ] && clone_i_array+=($src_child)
						[ "$clone" ] && clone_a_array+=([$src_child]="$clone")
						dest_a_array+=([$src_child]="$dest_child")
						#echo "[SORT] classified as dataset ($src_child)"
			;;

			*)
						exclude_i_array+=($src_child)
						#echo "[SORT] classified as else ($src_child)"
			;;



		esac

	done

done

do_verblist

}



do_verblist () {

[ "$verblist" = 1 ] && do_print_include_i_array

[ "$verb_incl"  = 1 ] && do_print_include_a_array
[ "$verb_dest"  = 1 ] && do_print_dest_a_array
[ "$verb_clone" = 1 ] && do_print_clone_a_array


}



do_print_include_i_array () {
printf "\n---------------------------------- do_print_include_i_array --------------------------------\n" 1>&3
	#sleep 0.1 # to sync logging

	printf '[LIST1] %20s\n' "include_i_array :" 1>&3
	printf '[LIST1]                      %s\n' "${include_i_array[@]}" 1>&3

	printf "[LIST1] %20s\n" 'parent_i_array :' 1>&3
	printf "[LIST1]                      %s\n" "${parent_i_array[@]}" 1>&3

	printf "[LIST1] %20s\n" 'container_i_array :' 1>&3
	printf "[LIST1]                      %s\n" "${container_i_array[@]}" 1>&3

	printf "[LIST1] %20s\n" "dataset_i_array :" 1>&3
	printf "[LIST1]                      %s\n" "${dataset_i_array[@]}" 1>&3

	printf "[LIST1] %20s\n" "clone_i_array :" 1>&3
	printf "[LIST1]                      %s\n" "${clone_i_array[@]}" 1>&3

	printf "[LIST1] %20s\n" 'exclude_i_array :' 1>&3
	printf "[LIST1]                      %s\n" "${exclude_i_array[@]}" 1>&3

	echo "------------------------------------------------------------------------------------" 1>&3

}



do_print_include_a_array () {
printf "\n---------------------------------- do_print_include_a_array --------------------------------\n" 1>&3
	#sleep 0.1 # to sync logging

	printf '[LIST2] %20s\n' "include_a_array :" 1>&3

	for i in ${!include_a_array[@]} ;do
		printf '[LIST2] %18s = %s\n' "${include_a_array[$i]}" "$i" 1>&3
	done

	echo "------------------------------------------------------------------------------------" 1>&3

}



do_print_dest_a_array () {
printf "\n---------------------------------- do_print_dest_a_array --------------------------------\n" 1>&3
	#sleep 0.1 # to sync logging

	printf '[LIST3] %20s\n' "dest_a_array :" 1>&3

	for i in ${!dest_a_array[@]} ;do
		printf '[LIST3] %18s = %s\n' "src <"  "$i" 1>&3
		printf '[LIST3] %18s = %s\n' "dest >" "${dest_a_array[$i]}" 1>&3
	done

	echo "------------------------------------------------------------------------------------" 1>&3

}

do_print_clone_a_array () {
printf "\n---------------------------------- do_print_clone_a_array --------------------------------\n" 1>&3
	#sleep 0.1 # to sync logging

	printf '[LIST4] %20s\n' "clone_a_array :"  1>&3

	for i in ${!clone_a_array[@]} ;do
		printf '[LIST4] %20s %s\n' "clone < ="  "$i" 1>&3
		printf '[LIST4] %20s %s\n' "origin > =" "${clone_a_array[$i]}" 1>&3
	done

	echo "------------------------------------------------------------------------------------" 1>&3

}



do_declare_arrays () {

declare -ag include_i_array
declare -ag parent_i_array
declare -ag container_i_array
declare -ag dataset_i_array
declare -ag exclude_i_array
declare -ag clone_i_array
declare -Ag include_a_array
declare -Ag dest_a_array
declare -Ag clone_a_array

}



