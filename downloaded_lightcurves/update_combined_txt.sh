#!/usr/bin/env bash
for i in *_classification.txt ;do 
 grep 'class = RR' $i && continue 
 grep "asassn_id = $(basename $i _classification.txt)"'$' combined.txt && continue 
 cat $i >> combined.txt 
done
