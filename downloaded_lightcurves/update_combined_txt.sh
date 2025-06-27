#!/usr/bin/env bash
for i in *_classification.txt ;do 
 ADD_THIS_STAR_TO_COMBINED_TXT=1
 ASASSNID=$(basename $i _classification.txt)
 if grep --quiet 'class = RR' $i ;then
  ADD_THIS_STAR_TO_COMBINED_TXT=0
 fi
 if grep --quiet "^$ASASSNID," ../lightcurves/RR_objects_outside_rr_region.csv ;then
  ADD_THIS_STAR_TO_COMBINED_TXT=1
 fi
 if grep --quiet "asassn_id = $ASASSNID"'$' combined.txt ;then
  ADD_THIS_STAR_TO_COMBINED_TXT=0
 fi
 if [ $ADD_THIS_STAR_TO_COMBINED_TXT -eq 1 ];then
  cat $i >> combined.txt 
  if ! grep --quiet 'visual_inspection_comments' $i ;then
   echo "color_string =
visual_inspection_comments =" >> combined.txt
  fi
 fi
done
