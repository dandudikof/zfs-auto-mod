


do_sort_list1() {

printf "\n--------------------------------------( do_sort_list1 )-----------------------------------------\n" 1>&5
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

include_array+=($s_pool)
parent_array+=($s_pool)
include_Array+=([$s_pool]=p)

[ "$strip_pool"  = 1 ] && dest_Array+=([$s_pool]="$d_path")
[ "$strip_pool" != 1 ] && dest_Array+=([$s_pool]="$d_path/$s_pool")

for lset in $lsets ; do
	for src_child in $($s_zfs list -Hr -o name $lset) ;do

		[ "$src_child" = "$s_pool" ] && continue

		[ "$strip_pool"  = 1 ] && dest_child="$d_path/${src_child#${s_pool}/}"
		[ "$strip_pool" != 1 ] && dest_child="$d_path/$src_child"

		local lret="$($s_zfs get -s local,received -H -o value $pfix:incl $src_child)"
		local iret="$($s_zfs get -s inherited -H -o value $pfix:incl $src_child)"
		local excl="$($s_zfs get -s local,inherited,received -H -o value $pfix:excl $src_child)"
		local clone="$($s_zfs get -t filesystem,volume -H -o value origin $src_child)"
		
		[ "$src_child" = "$lset" ] && [ -z "$lret" ] && lret=$set_type
		[ "$clone" = "-" ] && unset clone

		if [ "$excl" = "1" ] ;then

					exclude_array+=($src_child)
					#echo "[SORT] classified as excluded ($src_child)"
		
		elif [ "$lret" = "p" ] ;then

					include_array+=($src_child)
					parent_array+=($src_child)
					include_Array+=([$src_child]=p)
					dest_Array+=([$src_child]="$dest_child")
					#echo "[SORT] classified as parent ($src_child)"

		elif [ "$lret" = "c" ] ;then

					include_array+=($src_child)
					container_array+=($src_child)
					include_Array+=([$src_child]=c)
					dest_Array+=([$src_child]="$dest_child")
					#echo "[SORT] classified as container ($src_child)"

		else

					include_array+=($src_child)
					dataset_array+=($src_child)
					[ "$clone" ] || include_Array+=([$src_child]=d)
					[ "$clone" ] && include_Array+=([$src_child]=cl)
					[ "$clone" ] && temp_clone_array+=($src_child)
					[ "$clone" ] && temp_clone_Array+=([$src_child]="$clone")
					dest_Array+=([$src_child]="$dest_child")
					#echo "[SORT] classified as else-dataset ($src_child)"

		fi

	done

done

do_clone_array_sort

do_verblist

}



do_sort_list2() {
printf "\n--------------------------------------( do_sort_list2 )-----------------------------------------\n" 1>&5
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

include_array+=($s_pool)
parent_array+=($s_pool)
include_Array+=([$s_pool]=p)

[ "$strip_pool"  = 1 ] && dest_Array+=([$s_pool]="$d_path")
[ "$strip_pool" != 1 ] && dest_Array+=([$s_pool]="$d_path/$s_pool")

for lset in $lsets ; do
	for src_child in $($s_zfs list -Hr -o name $lset) ;do

		[ "$src_child" = "$s_pool" ] && continue

		[ "$strip_pool"  = 1 ] && dest_child="$d_path/${src_child#${s_pool}/}"
		[ "$strip_pool" != 1 ] && dest_child="$d_path/$src_child"

		local lret="$($s_zfs get -s local,received -H -o value $pfix:incl $src_child)"
		local excl="$($s_zfs get -s local,inherited,received -H -o value $pfix:excl $src_child)"
		local clone="$($s_zfs get -t filesystem,volume -H -o value origin $src_child)"

		[ "$excl" = 1 ] && unset lret
		[ "$clone" = "-" ] && unset clone

		case "$lret" in

			p)
						include_array+=($src_child)
						parent_array+=($src_child)
						include_Array+=([$src_child]=p)
						dest_Array+=([$src_child]="$dest_child")
						#echo "[SORT] classified as parent ($src_child)"
			;;

			c)
						include_array+=($src_child)
						container_array+=($src_child)
						include_Array+=([$src_child]=c)
						dest_Array+=([$src_child]="$dest_child")
						#echo "[SORT] classified as container ($src_child)"
			;;

			d)
						include_array+=($src_child)
						dataset_array+=($src_child)
						[ "$clone" ] || include_Array+=([$src_child]=d)
						[ "$clone" ] && include_Array+=([$src_child]=cl)
						[ "$clone" ] && temp_clone_array+=($src_child)
						[ "$clone" ] && temp_clone_Array+=([$src_child]="$clone")
						dest_Array+=([$src_child]="$dest_child")
						#echo "[SORT] classified as dataset ($src_child)"
			;;

			*)
						exclude_array+=($src_child)
						#echo "[SORT] classified as else ($src_child)"
			;;



		esac

	done

done

do_clone_array_sort

do_verblist

}



do_clone_array_sort () {
printf "\n--------------------------------------( do_clone_array_sort )-----------------------------------\n" 1>&5
		# re-sorting of clone arrays for correct order in clone of clone situations

declare -a sort_clone_array

local clone

for clone in "${temp_clone_array[@]}" ;do

	unset origin_clone_check
	
	until [ "$origin_clone_check" = end ] ;do 
		
		local origin_set="${temp_clone_Array["${clone:-null}"]%@*}"
		local origin_clone_check="${temp_clone_Array["${origin_set:-null}"]:-end}"
		
		if [ "$origin_clone_check" != end ] ;then
		
			sort_clone_array+=($clone)
			clone=$origin_set
			
		else
			
			sort_clone_array+=($clone)
			
		fi
	
	done
	
done

unset clone #just in case

for ((i=${#sort_clone_array[@]}-1; i>=0; i--)) ;do
	
	clone="${sort_clone_array[$i]}"
		
	[ "${clone_Array["$clone"]}" ] && continue
	
	clone_array+=($clone)
	clone_Array+=([$clone]=${temp_clone_Array[$clone]})

done

unset temp_clone_array
unset temp_clone_Array
unset sort_clone_array

}



do_verblist () {

[ "$verblist" = 1 ] && do_print_include_array

[ "$verb_incl"  = 1 ] && do_print_include_Array
[ "$verb_dest"  = 1 ] && do_print_dest_Array
[ "$verb_clone" = 1 ] && do_print_clone_Array


}



do_print_temp_clone_arrays () {
printf "\n--------------------------------------( do_print_temp_clone_arrays )----------------------------\n" 1>&3

	printf "[LIST01] %20s\n" "temp_clone_array :" 1>&3
	printf "[LIST01]                      %s\n" "${temp_clone_array[@]}" 1>&3

	printf '[LIST01] %20s\n' "temp_clone_Array :"  1>&3

	for i in ${!temp_clone_Array[@]} ;do
		printf '[LIST01] %20s %s\n' "clone < ="  "$i" 1>&3
		printf '[LIST01] %20s %s\n' "origin > =" "${temp_clone_Array[$i]}" 1>&3
	done

	echo "------------------------------------------------------------------------------------------------" 1>&3
	
}



do_print_sort_clone_array () {
printf "\n--------------------------------------( do_print_sort_clone_array )---------------------------\n" 1>&3

	printf "[LIST02] %20s\n" "sort_clone_array :" 1>&3
	printf "[LIST02]                      %s\n" "${sort_clone_array[@]}" 1>&3

	echo "------------------------------------------------------------------------------------------------" 1>&3

}



do_print_include_array () {
printf "\n--------------------------------------( do_print_include_array )--------------------------------\n" 1>&3
	#sleep 0.1 # to sync logging

	printf '[LIST1] %20s\n' "include_array :" 1>&3
	printf '[LIST1]                      %s\n' "${include_array[@]}" 1>&3

	printf "[LIST1] %20s\n" 'parent_array :' 1>&3
	printf "[LIST1]                      %s\n" "${parent_array[@]}" 1>&3

	printf "[LIST1] %20s\n" 'container_array :' 1>&3
	printf "[LIST1]                      %s\n" "${container_array[@]}" 1>&3

	printf "[LIST1] %20s\n" "dataset_array :" 1>&3
	printf "[LIST1]                      %s\n" "${dataset_array[@]}" 1>&3

	printf "[LIST1] %20s\n" "clone_array :" 1>&3
	printf "[LIST1]                      %s\n" "${clone_array[@]}" 1>&3

	printf "[LIST1] %20s\n" 'exclude_array :' 1>&3
	printf "[LIST1]                      %s\n" "${exclude_array[@]}" 1>&3

	echo "------------------------------------------------------------------------------------------------" 1>&3

}



do_print_include_Array () {
printf "\n--------------------------------------( do_print_include_Array )------------------------------\n" 1>&3
	#sleep 0.1 # to sync logging

	printf '[LIST2] %20s\n' "include_Array :" 1>&3

	for i in ${!include_Array[@]} ;do
		printf '[LIST2] %18s = %s\n' "${include_Array[$i]}" "$i" 1>&3
	done

	echo "------------------------------------------------------------------------------------------------" 1>&3

}



do_print_dest_Array () {
printf "\n--------------------------------------( do_print_dest_Array )---------------------------------\n" 1>&3
	#sleep 0.1 # to sync logging

	printf '[LIST3] %20s\n' "dest_Array :" 1>&3

	for i in ${!dest_Array[@]} ;do
		printf '[LIST3] %18s = %s\n' "src <"  "$i" 1>&3
		printf '[LIST3] %18s = %s\n' "dest >" "${dest_Array[$i]}" 1>&3
	done

	echo "------------------------------------------------------------------------------------------------" 1>&3

}

do_print_clone_Array () {
printf "\n--------------------------------------( do_print_clone_Array )--------------------------------\n" 1>&3
	#sleep 0.1 # to sync logging

	printf '[LIST4] %20s\n' "clone_Array :"  1>&3

	for i in ${!clone_Array[@]} ;do
		printf '[LIST4] %20s %s\n' "clone < ="  "$i" 1>&3
		printf '[LIST4] %20s %s\n' "origin > =" "${clone_Array[$i]}" 1>&3
	done

	echo "------------------------------------------------------------------------------------------------" 1>&3

}




do_declare_arrays () {

declare -ag include_array
declare -ag parent_array
declare -ag container_array
declare -ag dataset_array
declare -ag exclude_array
declare -ag temp_clone_array
declare -ag clone_array
declare -Ag include_Array
declare -Ag dest_Array
declare -Ag temp_clone_Array
declare -Ag clone_Array

}



