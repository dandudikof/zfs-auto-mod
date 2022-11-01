


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

for lset in $lsets ; do
	for child in $($s_zfs list -Hr -o name $lset) ;do

		[ "$child" = "$s_pool" ] && continue

		local lret="$($s_zfs get $pfix:incl -s local,received -H -o value $child)"
		local iret="$($s_zfs get $pfix:incl -s inherited -H -o value $child)"
		
		[ "$child" = "$lset" ] && [ -z "$lret" ] && lret=d

		if [ "$lret" = "p" ] ;then

					include_i_array+=($child)
					parent_i_array+=($child)
					include_a_array+=([$child]=p)
					#echo "adding to parent and include array : $child"

		elif [ "$lret" = "c" ] ;then

					include_i_array+=($child)
					container_i_array+=($child)
					include_a_array+=([$child]=c)
					#echo "adding to container and include array : $child"

		elif [ "$lret" = "d" ] || [ "$iret" = "d" ] || [ "$iret" = "p" ] || [ "$iret" = "c" ] ;then

					include_i_array+=($child)
					dataset_i_array+=($child)
					include_a_array+=([$child]=d)
					#echo "adding to dataset and include array : $child"

		elif [ "$lret" = "e" ] || [ "$iret" = "e" ] ;then

					exclude_i_array+=($child)
					#echo "adding to exclude array : $child"

		else

					include_i_array+=($child)
					dataset_i_array+=($child)
					include_a_array+=([$child]=d)
					#echo "adding to dataset and include array : $child"

		fi

	done
done

[ "$verblist" = 1 ] && do_print_i_array
[ "$verblist" = 2 ] && do_print_a_array

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

for lset in $lsets ; do
	for child in $($s_zfs list -Hr -o name $lset) ;do

		[ "$child" = "$s_pool" ] && continue

		local lret="$($s_zfs get $pfix:incl -s local,received -H -o value $child)"
		local iret="$($s_zfs get $pfix:incl -s inherited -H -o value $child)"
		
		[ "$child" = "$lset" ] && [ -z "$lret" ] && lret=p

		if [ "$lret" = "p" ]  ;then

					include_i_array+=($child)
					parent_i_array+=($child)
					include_a_array+=([$child]=p)
					#echo "adding to parent and include array : $child"

		elif [ "$lret" = "c" ] ;then

					include_i_array+=($child)
					container_i_array+=($child)
					include_a_array+=([$child]=c)
					#echo "adding to container and include array : $child"

		elif [ "$lret" = "d" ] || [ "$iret" = "d" ] || [ "$iret" = "p" ] || [ "$iret" = "c" ] ;then

					include_i_array+=($child)
					dataset_i_array+=($child)
					include_a_array+=([$child]=d)
					#echo "adding to dataset and include array : $child"

		elif [ "$lret" = "e" ] || [ "$iret" = "e" ] ;then

					exclude_i_array+=($child)
					#echo "adding to exclude array : $child"

		else

					include_i_array+=($child)
					dataset_i_array+=($child)
					include_a_array+=([$child]=d)
					#echo "adding to dataset and include array : $child"

		fi

	done
done

[ "$verblist" = 1 ] && do_print_i_array
[ "$verblist" = 2 ] && do_print_a_array

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

for lset in $lsets ; do
	for child in $($s_zfs list -Hr -o name $lset) ;do

		[ "$child" = "$s_pool" ] && continue

		local lret="$($s_zfs get $pfix:incl -s local,received -H -o value $child)"

		case "$lret" in

			p)
						include_i_array+=($child)
						parent_i_array+=($child)
						include_a_array+=([$child]=p)
						#echo "adding to parent and include array : $child"
			;;

			c)
						include_i_array+=($child)
						container_i_array+=($child)
						include_a_array+=([$child]=c)
						#echo "adding to container and include array : $child"
			;;

			d)
						include_i_array+=($child)
						dataset_i_array+=($child)
						include_a_array+=([$child]=d)
						#echo "adding to dataset and include array : $child"
			;;

			e)
						exclude_i_array+=($child)
						#echo "adding to exclude array : $child"
			;;

			*)
						exclude_i_array+=($child)
						#echo "adding to exclude array : $child"
			;;



		esac
	done
done

[ "$verblist" = 1 ] && do_print_i_array
[ "$verblist" = 2 ] && do_print_a_array

}



do_print_i_array () {
printf "\n---------------------------------- do_print_i_array --------------------------------\n" 1>&3
	#sleep 0.1 # to sync logging

	printf '[LIST1] %20s\n' "include_i_array :" 1>&3
	printf '[LIST1]                       %s\n' "${include_i_array[@]}" 1>&3

	printf "[LIST1] %20s\n" 'parent_i_array :' 1>&3
	printf "[LIST1]                       %s\n" "${parent_i_array[@]}" 1>&3

	printf "[LIST1] %20s\n" 'container_i_array :' 1>&3
	printf "[LIST1]                       %s\n" "${container_i_array[@]}" 1>&3

	printf "[LIST1] %20s\n" "dataset_i_array :" 1>&3
	printf "[LIST1]                       %s\n" "${dataset_i_array[@]}" 1>&3

	printf "[LIST1] %20s\n" 'exclude_i_array :' 1>&3
	printf "[LIST1]                       %s\n" "${exclude_i_array[@]}" 1>&3

	echo "------------------------------------------------------------------------------------" 1>&3

}



do_print_a_array () {
printf "\n---------------------------------- do_print_a_array --------------------------------\n" 1>&3
	#sleep 0.1 # to sync logging

	printf '[LIST2] include_a_array :\n' 1>&3

	for i in ${include_i_array[@]} ;do
		printf '[LIST2]               %s = %s\n' "${include_a_array[$i]}" "$i" 1>&3
	done

	echo "------------------------------------------------------------------------------------" 1>&3

}



do_declare_arrays () {

declare -ag include_i_array
declare -ag parent_i_array
declare -ag container_i_array
declare -ag dataset_i_array
declare -ag exclude_i_array
declare -Ag include_a_array

}



