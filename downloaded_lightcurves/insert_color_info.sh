#!/usr/bin/env bash

VAST_SCRIPT="/home/kirx/current_work/vast/util/search_databases_with_vizquery.sh"
if [ -d "/Users/zoesurles/Desktop/vsc_vast/vast" ];then
 VAST_SCRIPT="/Users/zoesurles/Desktop/vsc_vast/vast/util/search_databases_with_vizquery.sh"
fi

# Read the input file line by line
while IFS= read -r line; do
  # Check if the line contains "position ="
  if [[ $line == *"position ="* ]]; then
    POSITION="${line/position =/}"
  fi
  if [[ "$line" == "color_string =" ]]; then
    NEW_COLOR_STRING=$("$VAST_SCRIPT" $POSITION 2>&1 | grep '|')
    NEW_COLOR_STRING="${NEW_COLOR_STRING/object           | /}"
    echo "color_string = $NEW_COLOR_STRING"
  else
    # If the line doesn't contain "asassn_id =", print it as is
    echo "$line"
  fi
done < combined.txt > combined.tmp
cp -v combined.txt combined.txt_backup$(date "+%Y%m%d_%H%M%S")
mv -v combined.tmp combined.txt
