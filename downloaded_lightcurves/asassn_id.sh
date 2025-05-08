#!/usr/bin/env bash

#for i in *_classification.txt; do 
#    if grep -q 'class = RR' "$i"; then                                                     
#        asassn_id=$(basename "$i" _classification.txt)
#        if ! grep -q "asassn_id = $asassn_id" RRconfirmed.txt; then
#            echo "$asassn_id" >> asassn_id_only.txt
#        fi
#    fi
#done

# Select $asassn_id of RR Lyrae stars
if [ ! -f ../lightcurves/distance_color_type_for_all_stars.txt ];then
 echo "../lightcurves/distance_color_type_for_all_stars.txt  -- classification file not found"
 exit 1
fi

grep 'FinalType= RR' ../lightcurves/distance_color_type_for_all_stars.txt | awk '{print $2}' > asassn_id_only.txt

# need to figure out a way to continue to add to the asassn_id_only.txt without duplicating stars that have already been added to the file
