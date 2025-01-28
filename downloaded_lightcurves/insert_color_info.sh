#!/usr/bin/env bash

### Setup

# Kirill's laptop
VAST_SCRIPT="/home/kirx/current_work/vast/util/search_databases_with_vizquery.sh"
# Zoe's laptop
if [ -d "/Users/zoesurles/Desktop/vsc_vast/vast" ];then
 VAST_SCRIPT="/Users/zoesurles/Desktop/vsc_vast/vast/util/search_databases_with_vizquery.sh"
fi
# ariel server
if [ -d "/home/kirill/variablestars/vast" ];then
 VAST_SCRIPT="/home/kirill/variablestars/vast/util/search_databases_with_vizquery.sh"
fi

# Check setup
if [ ! -x "$VAST_SCRIPT" ];then
 echo "ERROR in $0: cannot find VaST VizieR search script $VAST_SCRIPT"
 exit 1
fi

if [ ! -f combined.txt ];then
 echo "ERROR in $0: cannot find combined.txt"
 exit 1
fi

#
if [ ! -f ../lightcurves/g_band_magnitude_information.txt ];then
 echo "ERROR in $0: cannot find ../lightcurves/g_band_magnitude_information.txt"
 exit 1
fi


# Read the input file line by line
while IFS= read -r line; do

  # NEW: add median mag to the human-readble comment
  if [[ $line == *"asassn_id ="* ]]; then
   ASASSN_ID="${line/asassn_id = /}"
  elif [[ $line == *"visual_inspection_comments ="* ]]; then
   # check if the median magnitude comment has been inserted before
   if [[ $line != *"median_g_mag="* ]]; then
    # modify the line if in includes the visual_inspection_comments  
    MEDIANgMAG=$(grep " $ASASSN_ID$" ../lightcurves/g_band_magnitude_information.txt | awk '{print $2}')
    if [ -n "$MEDIANgMAG" ];then
     ORIGINAL_LINE="$line"
     line="$ORIGINAL_LINE  median_g_mag=$MEDIANgMAG"
    fi
   fi
  fi


  # Check if the line contains "position ="
  if [[ $line == *"position ="* ]]; then
    POSITION="${line/position =/}"
  fi
  # Check if the line matches exacltly "color_string =" meaning the color information has not been added yet
  if [[ "$line" == "color_string =" ]]; then
    NEW_COLOR_STRING=$("$VAST_SCRIPT" $POSITION 2>&1 | grep '|')
    NEW_COLOR_STRING="${NEW_COLOR_STRING/object           | /}"
    echo "color_string = $NEW_COLOR_STRING"
  else
    # If the line doesn't match exactly "color_string =", print the line as it is
    echo "$line"
  fi
done < combined.txt > combined.tmp
cp -v combined.txt combined.txt_backup$(date "+%Y%m%d_%H%M%S")
mv -v combined.tmp combined.txt
