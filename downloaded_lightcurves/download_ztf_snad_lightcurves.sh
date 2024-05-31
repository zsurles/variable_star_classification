#!/usr/bin/env bash

function download_json_lightcurve_data_from_ztf_snad {
 # Parse and check the input
 # RA
 if [ -z "$1" ];then
  echo "ERROR in download_json_lightcurve_data_from_ztf_snad(): expecting the RA in degrees a function argument"
  exit 1
 fi
 RA_DEG="$1"
 if ! echo "$RA_DEG" | awk '{if ($1 ~ /^[0-9]*\.?[0-9]+$/ && $1 >= 0.0 && $1 <= 360.0) exit 0; else exit 1}'; then
  echo "ERROR in download_json_lightcurve_data_from_ztf_snad(): RA_DEG does not contain a valid floating point number between 0.0 and 360.0"
  exit 1
 fi
 # Dec
 if [ -z "$2" ];then
  echo "ERROR in download_json_lightcurve_data_from_ztf_snad(): expecting the Dec in degrees a function argument"
  exit 1
 fi
 DEC_DEG="$2"
 if ! echo "$DEC_DEG" | awk '{if ($1 ~ /^-?[0-9]*\.?[0-9]+$/ && $1 >= -90.0 && $1 <= 90.0) exit 0; else exit 1}'; then
  echo "ERROR in download_json_lightcurve_data_from_ztf_snad(): DEC_DEG does not contain a valid floating point number between -90.0 and 90.0"
  exit 1
 fi

 # Download the data
 curl --silent "http://db.ztf.snad.space/api/v3/data/latest/circle/full/json?ra=$RA_DEG&dec=$DEC_DEG&radius_arcsec=1"
 if [ $? -ne 0 ];then
  echo "ERROR in download_json_lightcurve_data_from_ztf_snad(): ERROR running curl"
  return 1
 fi
}

function produce_csv_lightcurve_from_json_file {
 # Parse and check the input
 if [ -z "$1" ];then
  echo "ERROR in produce_csv_lightcurve_from_json_file(): expecting the input json file as a function argument"
  exit 1
 fi
 INPUT_FILE_JSON="$1"
 if [ ! -f "$INPUT_FILE_JSON" ];then
  echo "ERROR in produce_csv_lightcurve_from_json_file(): the input file $INPUT_FILE_JSON is not found"
  exit 1
 fi 
 if [ ! -s "$INPUT_FILE_JSON" ];then
  echo "ERROR in produce_csv_lightcurve_from_json_file(): the input file $INPUT_FILE_JSON is empty"
  exit 1
 fi 

 N_JSON_KEYS=$(jq -r 'keys[]' "$INPUT_FILE_JSON" | wc -l)
 if [ $N_JSON_KEYS -lt 1 ];then
  echo "ERROR in produce_csv_lightcurve_from_json_file(): no JSON data found"
  return 1
 fi
 
 # Parse the json file and produce csv
 echo "oid,filter,mjd,mag,magerr,clrcoeff"
 jq -r 'keys[]' "$INPUT_FILE_JSON" | while read ZTF_OBJ_ID ;do
  FILTER=$(jq -r ".\"$ZTF_OBJ_ID\".meta.filter" "$INPUT_FILE_JSON")
  jq -r ".\"$ZTF_OBJ_ID\".lc[] | \"\(.mjd) \(.mag) \(.magerr) \(.clrcoeff)\"" "$INPUT_FILE_JSON" | while read MJD MAG ERR CLRCOEFF ;do
   echo "$ZTF_OBJ_ID,$FILTER,$MJD,$MAG,$ERR,$CLRCOEFF"
  done
 done
}

# Check if jq and other external programs are installed
LIST_OF_MISSING_PROGRAMS=""
MISSING_PROGRAM=0
for TESTED_PROGRAM in jq awk curl ;do
 echo -n "Looking for $TESTED_PROGRAM - "
 if ! command -v $TESTED_PROGRAM &>/dev/null ;then
  MISSING_PROGRAM=1
  LIST_OF_MISSING_PROGRAMS="$LIST_OF_MISSING_PROGRAMS  $TESTED_PROGRAM"
  echo -e "\033[01;31mNOT found\033[00m"
 else
  echo -e "\033[01;32mFound\033[00m"
 fi
done
if [ $MISSING_PROGRAM -ne 0 ];then
 echo "Please install the following programs before running this script: $LIST_OF_MISSING_PROGRAMS"
 exit 1
fi


# Read the input file line by line
while IFS= read -r line; do
 # Check if the line contains "position ="
 if [[ $line == *"position ="* ]]; then
  POSITION="${line/position =/}"
 fi
 if [[ $line == *"asassn_id ="* ]]; then
  ASASSN_ID="${line/asassn_id = /}"
  #echo "$ASASSN_ID  $POSITION"
  TMP_ZTF_JSON_FILENAME="${ASASSN_ID}_ztf.json"
  OUTPUT_ZTF_CSV_FILENAME="${ASASSN_ID}_ztf.csv"
  if [ -s "$OUTPUT_ZTF_CSV_FILENAME" ];then
   echo "$OUTPUT_ZTF_CSV_FILENAME already exist"
   continue
  fi
  # Check if the Dec is winthin the ZTF range
  if ! echo "$POSITION" | awk '{if ($2 ~ /^-?[0-9]*\.?[0-9]+$/ && $2 >= -30.0 && $2 <= 90.0) exit 0; else exit 1}'; then
   echo "The declination in $POSITION is bewlow -30 deg"
   continue
  fi
  # Fetch ZTF data
  download_json_lightcurve_data_from_ztf_snad $POSITION > "$TMP_ZTF_JSON_FILENAME"
  if [ $? -ne 0 ];then
   echo "Something whent wrong while downloading the data"
   continue
  fi
  if [ ! -f "$TMP_ZTF_JSON_FILENAME" ];then
   echo "ERROR: $TMP_ZTF_JSON_FILENAME was not created"
   continue
  fi
  if [ ! -s "$TMP_ZTF_JSON_FILENAME" ];then
   echo "ERROR: $TMP_ZTF_JSON_FILENAME is empty"
   continue
  fi
  # convert json to csv
  produce_csv_lightcurve_from_json_file "$TMP_ZTF_JSON_FILENAME" > "$OUTPUT_ZTF_CSV_FILENAME" 
  if [ $? -ne 0 ];then
   echo "WARNING: somehting whent wrog while converting json ($TMP_ZTF_JSON_FILENAME) to csv ($OUTPUT_ZTF_CSV_FILENAME) file - no ZTF data for this object?"
   rm -f "$TMP_ZTF_JSON_FILENAME"
   continue
  else
   echo "Writing $OUTPUT_ZTF_CSV_FILENAME"
  fi
  # Check if the output file is empty
  N_LINES=$(cat "$OUTPUT_ZTF_CSV_FILENAME" | wc -l)
  if [ $N_LINES -lt 3 ];then
   echo "$OUTPUT_ZTF_CSV_FILENAME has only $N_LINES lines in it - removing"
   rm -f "$OUTPUT_ZTF_CSV_FILENAME"
  fi
  # Remove the json file
  rm -f "$TMP_ZTF_JSON_FILENAME"
 fi
done < combined.txt
