#!/usr/bin/env bash

# Kirill's laptop
LIB_VIZQUERY="/home/kirx/current_work/vast/lib/vizquery"
# Zoe's laptop
if [ -d "/Users/zoesurles/Desktop/vsc_vast/vast" ];then
 LIB_VIZQUERY="/Users/zoesurles/Desktop/vsc_vast/vast/lib/vizquery"
fi
# ariel server
if [ -d "/home/kirill/variablestars/vast" ];then
 LIB_VIZQUERY="/home/kirill/variablestars/vast/lib/vizquery"
fi

# Check setup
if [ ! -x "$LIB_VIZQUERY" ];then
 echo "ERROR in $0: cannot find VaST VizieR search script $LIB_VIZQUERY"
 exit 1
fi


if [ ! -f rrlyr_vsx_clean2_magnitude_filtered.txt ];then
 echo "ERROR in $0: no input file rrlyr_vsx_clean2_magnitude_filtered.txt"
 exit 1
fi

echo "Reading the input list of stars from 'rrlyr_vsx_clean2_magnitude_filtered.txt' and writing the output to 'distance_color_type_for_all_stars.txt'
The script $0 will take a very long time to run!!!"

if [ -f distance_color_type_for_all_stars.txt ];then
 echo "Found 'distance_color_type_for_all_stars.txt' from a previous run - let's back up it"
 mv -v distance_color_type_for_all_stars.txt distance_color_type_for_all_stars.txt_backup$(date "+%Y%m%d_%H%M%S")
fi

grep -v 'Star Type' rrlyr_vsx_clean2_magnitude_filtered.txt | while read VSXType VSXRA VSXDec VSXMag VSXName ;do

 # Get ASASSN ID from VSX name
 # '$' here is the mark that VSXName should be at the end of the line
 ASASSN_ID=$(grep "  $VSXName$" asassn_vsx_id.txt | awk '{print $1}')
 # if there is no $ASASSN_ID - we don't have classification for this star
 if [ -z "$ASASSN_ID" ];then
  continue
 fi

 ML_CLASSIFIER_TYPE=$(cat ../downloaded_lightcurves/"$ASASSN_ID"_classification.txt | grep "class = " | awk '{print $3}')
 if [ -z "$ML_CLASSIFIER_TYPE" ];then
  ML_CLASSIFIER_TYPE="NA"
 fi
 
 VISUAL_CLASSIFICATION=$(grep -A3 "asassn_id = $ASASSN_ID$" ../downloaded_lightcurves/combined.txt | grep 'visual_inspection_comments = ' | sed 's/visual_inspection_comments = //g' | sed 's/true //g' | awk -F',' '{print $1}' | awk '{print $1}')
 if [ -z "$VISUAL_CLASSIFICATION" ];then
  VISUAL_CLASSIFICATION="NA"
 fi
 
 # Get ASASSN median g magnitude from g_band_magnitude_information.txt
 ASASSN_MEDIAN_g_MAG=$(grep " $ASASSN_ID$" g_band_magnitude_information.txt | awk '{printf "%6.3f", ($2 != "" ? $2 : 99.999)}')
 if [ -z "$ASASSN_MEDIAN_g_MAG" ];then
  ASASSN_MEDIAN_g_MAG="99.999"
 fi

 # Gaia optical magnitudes 
 # https://vizier.cds.unistra.fr/viz-bin/VizieR-3?-source=I/355/gaiadr3&-out.max=50&-out.form=HTML%20Table&-out.add=_r&-out.add=_RAJ,_DEJ&-sort=_r&-oc.form=sexa
 #lib/vizquery -site=vizier.cds.unistra.fr -mime=text -source=I/355/gaiadr3 -out.max=1 -out.form=mini   -sort=_r -c='278.12175 -33.74589' -c.rs=1.5 -out=DR3Name,Gmag,e_Gmag,BPmag,e_BPmag,RPmag,e_RPmag 2>&1 | grep -A3 'DR3Name ' | grep '\.'
 # Example output:
 # Gaia DR3 2875539776437822592 12.868528  0.011965 13.166146  0.038479 12.473855  0.024048
 GAIA_DR3_INFO=$($LIB_VIZQUERY -site=vizier.cds.unistra.fr -mime=text -source=I/355/gaiadr3 -out.max=1 -out.form=mini   -sort=_r -c="$VSXRA $VSXDec" -c.rs=1.5 -out=DR3Name,Gmag,e_Gmag,BPmag,e_BPmag,RPmag,e_RPmag 2>&1 | grep -A3 'DR3Name ' | grep '\.')
 GAIA_DR3_NAMESTRING=$(echo "$GAIA_DR3_INFO" | awk '{print $1" "$2" "$3}')
 if [ -z "$GAIA_DR3_INFO" ] || [ -z "$GAIA_DR3_NAMESTRING" ] || [ "$GAIA_DR3_NAMESTRING" = "  " ] ;then
  #                    Gaia DR3 6735063943477003008
  GAIA_DR3_NAMESTRING="Gaia DR3 XXXXXXXXXXXXXXXXXXX"
 fi
 GMAG=$(echo "$GAIA_DR3_INFO" | awk '{printf "%6.3f", ($4 != "" ? $4 : 99.999)}')
 GMAG_ERR=$(echo "$GAIA_DR3_INFO" | awk '{printf "%5.3f", ($5 != "" ? $5 : 9.999)}')
 BPMAG=$(echo "$GAIA_DR3_INFO" | awk '{printf "%6.3f", ($6 != "" ? $6 : 99.999)}')
 BPMAG_ERR=$(echo "$GAIA_DR3_INFO" | awk '{printf "%5.3f", ($7 != "" ? $7 : 9.999)}')
 RPMAG=$(echo "$GAIA_DR3_INFO" | awk '{printf "%6.3f", ($8 != "" ? $8 : 99.999)}')
 RPMAG_ERR=$(echo "$GAIA_DR3_INFO" | awk '{printf "%5.3f", ($9 != "" ? $9 : 9.999)}')
 
 
 # Distance from Bailer-Jones+, 2021
 # http://vizier.cds.unistra.fr/viz-bin/VizieR?-source=I/352&-to=3
 # lib/vizquery -site=vizier.cds.unistra.fr -mime=text -source=I/352 -out.max=1 -out.form=mini   -sort=_r -c='278.12175 -33.74589' -c.rs=1.5 -out=rgeo,b_rgeo,B_rgeo 2>&1 | grep -A3 'rgeo (pc)' | grep '\.'
 BailerJones_DISTANCE=$($LIB_VIZQUERY -site=vizier.cds.unistra.fr -mime=text -source=I/352 -out.max=1 -out.form=mini   -sort=_r -c="$VSXRA $VSXDec" -c.rs=1.5 -out=rgeo,b_rgeo,B_rgeo 2>&1 | grep -A3 'rgeo (pc)' | grep '\.')
 if [ -n "$BailerJones_DISTANCE" ] ;then
  DISTANCE=$(echo "$BailerJones_DISTANCE" | awk '{printf "%5.0f", $1}')
  DISTANCE_LOW=$(echo "$BailerJones_DISTANCE" | awk '{printf "%5.0f", $2}')
  DISTANCE_HIGH=$(echo "$BailerJones_DISTANCE" | awk '{printf "%5.0f", $3}')
 else
  DISTANCE="99999"
  DISTANCE_LOW="99999"
  DISTANCE_HIGH="99999"
 fi

 # Infrared colors from 2MASS catalog
 # https://vizier.cds.unistra.fr/viz-bin/VizieR-3?-source=II/246/out&-out.max=50&-out.form=HTML%20Table&-out.add=_r&-out.add=_RAJ,_DEJ&-sort=_r&-oc.form=sexa
 # lib/vizquery -site=vizier.cds.unistra.fr -mime=text -source=II/246 -out.max=1 -out.form=mini   -sort=_r -c='278.12175 -33.74589' -c.rs=1.5 -out=2MASS,Jmag,e_Jmag,Hmag,e_Hmag,Kmag,e_Kmag  2>&1 | grep -A3 '2MASS  ' | grep '\.'
 TWOMASS_INFO=$($LIB_VIZQUERY -site=vizier.cds.unistra.fr -mime=text -source=II/246 -out.max=1 -out.form=mini   -sort=_r -c="$VSXRA $VSXDec" -c.rs=1.5 -out=2MASS,Jmag,e_Jmag,Hmag,e_Hmag,Kmag,e_Kmag  2>&1 | grep -A3 '2MASS  ' | grep '\.')
 JMAG=$(echo "$TWOMASS_INFO" | awk '{printf "%6.3f", ($2 != "" ? $2 : 99.999)}')
 JMAG_ERR=$(echo "$TWOMASS_INFO" | awk '{printf "%5.3f", ($3 != "" ? $3 : 9.999)}')
 KMAG=$(echo "$TWOMASS_INFO" | awk '{printf "%6.3f", ($6 != "" ? $6 : 99.999)}')
 KMAG_ERR=$(echo "$TWOMASS_INFO" | awk '{printf "%5.3f", ($7 != "" ? $7 : 9.999)}')
 
 # Check if the values are reasonable (possible catalog parsing issues)
 TWOMASS_PARSING_ERROR=0
 echo "$JMAG" | awk '{ if ( $1 > 1.0 && $1 < 20.0 ) exit 0; else exit 1; }'
 if [ $? -ne 0 ];then
  TWOMASS_PARSING_ERROR=1
 fi
 echo "$JMAG_ERR" | awk '{ if ( $1 > 0.0 && $1 < 1.0 ) exit 0; else exit 1; }'
 if [ $? -ne 0 ];then
  TWOMASS_PARSING_ERROR=1
 fi
 echo "$KMAG" | awk '{ if ( $1 > 1.0 && $1 < 20.0 ) exit 0; else exit 1; }'
 if [ $? -ne 0 ];then
  TWOMASS_PARSING_ERROR=1
 fi
 echo "$KMAG_ERR" | awk '{ if ( $1 > 0.0 && $1 < 1.0 ) exit 0; else exit 1; }'
 if [ $? -ne 0 ];then
  TWOMASS_PARSING_ERROR=1
 fi
 if [ $TWOMASS_PARSING_ERROR -ne 0 ];then
  # Something went wrng when passing 2MASS catalog
  JMAG="99.999"
  JMAG_ERR="9.999"
  KMAG="99.999"
  KMAG_ERR="9.999"
 fi
 
 # Get extinction information
 GET_DUST_OUTPUT=$(./get_dust.py "$VSXRA" "$VSXDec" "$DISTANCE") 
 EXTINCTION_CORRECTION_JMAG_BESTDIST=$( ( echo "$GET_DUST_OUTPUT" | grep 'J band extinction' || echo "1 2 3 9.999" ) | awk '{printf "%5.3f\n", $4}')
 EXTINCTION_CORRECTION_KMAG_BESTDIST=$( ( echo "$GET_DUST_OUTPUT" | grep 'K band extinction' || echo "1 2 3 9.999" ) | awk '{printf "%5.3f\n", $4}')
 EXTINCTION_CORRECTION_GMAG_BESTDIST=$( ( echo "$GET_DUST_OUTPUT" | grep 'G band extinction' || echo "1 2 3 9.999" ) | awk '{printf "%5.3f\n", $4}')
 GAIA_COLOR_EXCESS_BESTDIST=$( ( echo "$GET_DUST_OUTPUT" | grep 'E(BP-RP): ' || echo "1 9.999" ) | awk '{printf "%5.3f\n", $2}')
 
 GET_DUST_OUTPUT=$(./get_dust.py "$VSXRA" "$VSXDec" "$DISTANCE_LOW") 
 EXTINCTION_CORRECTION_JMAG_DIST_LOW=$( ( echo "$GET_DUST_OUTPUT" | grep 'J band extinction' || echo "1 2 3 9.999" ) | awk '{printf "%5.3f\n", $4}')
 EXTINCTION_CORRECTION_KMAG_DIST_LOW=$( ( echo "$GET_DUST_OUTPUT" | grep 'K band extinction' || echo "1 2 3 9.999" ) | awk '{printf "%5.3f\n", $4}')
 EXTINCTION_CORRECTION_GMAG_DIST_LOW=$( ( echo "$GET_DUST_OUTPUT" | grep 'G band extinction' || echo "1 2 3 9.999" ) | awk '{printf "%5.3f\n", $4}')
 GAIA_COLOR_EXCESS_DIST_LOW=$( ( echo "$GET_DUST_OUTPUT" | grep 'E(BP-RP): ' || echo "1 9.999" ) | awk '{printf "%5.3f\n", $2}')
 
 GET_DUST_OUTPUT=$(./get_dust.py "$VSXRA" "$VSXDec" "$DISTANCE_HIGH") 
 EXTINCTION_CORRECTION_JMAG_DIST_HIGH=$( ( echo "$GET_DUST_OUTPUT" | grep 'J band extinction' || echo "1 2 3 9.999" ) | awk '{printf "%5.3f\n", $4}')
 EXTINCTION_CORRECTION_KMAG_DIST_HIGH=$( ( echo "$GET_DUST_OUTPUT" | grep 'K band extinction' || echo "1 2 3 9.999" ) | awk '{printf "%5.3f\n", $4}')
 EXTINCTION_CORRECTION_GMAG_DIST_HIGH=$( ( echo "$GET_DUST_OUTPUT" | grep 'G band extinction' || echo "1 2 3 9.999" ) | awk '{printf "%5.3f\n", $4}')
 GAIA_COLOR_EXCESS_DIST_HIGH=$( ( echo "$GET_DUST_OUTPUT" | grep 'E(BP-RP): ' || echo "1 9.999" ) | awk '{printf "%5.3f\n", $2}')
 
 # compute Gaia colors
 if [ -n "$BPMAG" ] && [ -n "$RPMAG" ] && [ -n "$BPMAG_ERR" ] && [ -n "$RPMAG_ERR" ] ;then
  GAIA_COLOR=$(echo "$BPMAG $RPMAG" | awk '{printf "%+5.3f\n", $1 - $2}')
  GAIA_COLOR_ERROR=$(echo "$BPMAG_ERR $RPMAG_ERR" | awk '{printf "%5.3f\n", sqrt($1*$1 + $2*$2) }' | awk '{printf "%5.3f", ($1 > 0.001 ? $1 : 0.001)}' | awk '{printf "%5.3f", ($1 < 9.999 ? $1 : 9.999)}')
  if [ -n "$GAIA_COLOR_EXCESS_BESTDIST" ] && [ -n "$GAIA_COLOR_EXCESS_DIST_LOW" ] && [ -n "$GAIA_COLOR_EXCESS_DIST_HIGH" ];then
   GAIA_INTRINSIC_COLOR_BESTDIST=$(echo "$GAIA_COLOR $GAIA_COLOR_EXCESS_BESTDIST" | awk '{printf "%+5.3f", $1-$2}')
   GAIA_INTRINSIC_COLOR_DIST_LOW=$(echo "$GAIA_COLOR $GAIA_COLOR_EXCESS_DIST_LOW" | awk '{printf "%+5.3f", $1-$2}')
   GAIA_INTRINSIC_COLOR_DIST_HIGH=$(echo "$GAIA_COLOR $GAIA_COLOR_EXCESS_DIST_HIGH" | awk '{printf "%+5.3f", $1-$2}')
   GAIA_INTRINSIC_COLOR_ERR=$(echo "$GAIA_COLOR_ERROR $GAIA_COLOR_EXCESS_DIST_LOW $GAIA_COLOR_EXCESS_DIST_HIGH" | awk '{printf "%5.3f\n", sqrt( $1*$1 + ($3-$2)*($3-$2) ) }')
   # debug
   #echo "DEBUG: GAIA_INTRINSIC_COLOR_ERR=$GAIA_INTRINSIC_COLOR_ERR GAIA_COLOR_ERROR=$GAIA_COLOR_ERROR GAIA_COLOR_EXCESS_DIST_LOW=$GAIA_COLOR_EXCESS_DIST_LOW GAIA_COLOR_EXCESS_DIST_HIGH=$GAIA_COLOR_EXCESS_DIST_HIGH  GAIA_COLOR_EXCESS_BESTDIST=$GAIA_COLOR_EXCESS_BESTDIST" 1>&2 
   #
  else
   GAIA_INTRINSIC_COLOR_BESTDIST="+9.999"
   GAIA_INTRINSIC_COLOR_DIST_LOW="+9.999"
   GAIA_INTRINSIC_COLOR_DIST_HIGH="+9.999"
   GAIA_INTRINSIC_COLOR_ERR="9.999"
  fi
 else
  GAIA_COLOR="+9.999"
  GAIA_COLOR_ERROR="9.999"
  GAIA_INTRINSIC_COLOR_BESTDIST="+9.999"
  GAIA_INTRINSIC_COLOR_DIST_LOW="+9.999"
  GAIA_INTRINSIC_COLOR_DIST_HIGH="+9.999"
  GAIA_INTRINSIC_COLOR_ERR="9.999"
 fi
 

 # M = m + 5 - 5 * log10(r_pc) - A
 # where M is the absolute magnitude
 # m is the apparent magnitude
 # r_pc is the distance in pc
 # A is the extinciton in magnitudes
 #echo "100" | awk '{print log($1)/log(10)}'
 if [ "$DISTANCE" != "99999" ] && [ -n "$GMAG" ] && [ "$GMAG" != "99.999" ] && [ -n "$JMAG" ] && [ "$JMAG" != "99.999" ] && [ -n "$DISTANCE" ] && [ -n "$DISTANCE_LOW" ] && [ -n "$DISTANCE_HIGH" ] && [ "$EXTINCTION_CORRECTION_JMAG_BESTDIST" ] && [ "$EXTINCTION_CORRECTION_JMAG_BESTDIST" != "99.999" ] ;then
  EXTINCTION_CORRECTED_ABSJMAG_BESTDIST=$(echo "$JMAG" "$DISTANCE" "$EXTINCTION_CORRECTION_JMAG_BESTDIST" | awk '{printf "%+6.3f", $1 + 5 - 5 * log($2)/log(10) - $3 }')
  EXTINCTION_CORRECTED_ABSJMAG_LOWDIST=$(echo "$JMAG" "$DISTANCE_LOW" "$EXTINCTION_CORRECTION_JMAG_DIST_LOW" | awk '{printf "%+6.3f", $1 + 5 - 5 * log($2)/log(10) - $3 }')
  EXTINCTION_CORRECTED_ABSJMAG_HIGHDIST=$(echo "$JMAG" "$DISTANCE_HIGH" "$EXTINCTION_CORRECTION_JMAG_DIST_HIGH" | awk '{printf "%+6.3f", $1 + 5 - 5 * log($2)/log(10) - $3 }')
  #
  EXTINCTION_CORRECTED_ABSGMAG_BESTDIST=$(echo "$GMAG" "$DISTANCE" "$EXTINCTION_CORRECTION_GMAG_BESTDIST" | awk '{printf "%+6.3f", $1 + 5 - 5 * log($2)/log(10) - $3 }')
  EXTINCTION_CORRECTED_ABSGMAG_LOWDIST=$(echo "$GMAG" "$DISTANCE_LOW" "$EXTINCTION_CORRECTION_GMAG_DIST_LOW" | awk '{printf "%+6.3f", $1 + 5 - 5 * log($2)/log(10) - $3 }')
  EXTINCTION_CORRECTED_ABSGMAG_HIGHDIST=$(echo "$GMAG" "$DISTANCE_HIGH" "$EXTINCTION_CORRECTION_GMAG_DIST_HIGH" | awk '{printf "%+6.3f", $1 + 5 - 5 * log($2)/log(10) - $3 }')
 else
  EXTINCTION_CORRECTED_ABSJMAG_BESTDIST="+9.999"
  EXTINCTION_CORRECTED_ABSJMAG_LOWDIST="+9.999"
  EXTINCTION_CORRECTED_ABSJMAG_HIGHDIST="+9.999"
  #
  EXTINCTION_CORRECTED_ABSGMAG_BESTDIST="+9.999"
  EXTINCTION_CORRECTED_ABSGMAG_LOWDIST="+9.999"
  EXTINCTION_CORRECTED_ABSGMAG_HIGHDIST="+9.999"
 fi


 # Decide on the final type
 FinalType="NA"
 if [ "$VISUAL_CLASSIFICATION" != "NA" ];then
  FinalType="$VISUAL_CLASSIFICATION"
 elif [ "$ML_CLASSIFIER_TYPE" = "RRL_ab" ];then
  FinalType="RRAB"
 elif [ "$ML_CLASSIFIER_TYPE" = "RRL_c" ];then
  FinalType="RRC"
 elif [ "$ML_CLASSIFIER_TYPE" = "RRL_d" ];then
  FinalType="RR(B)"
 elif [ "$ML_CLASSIFIER_TYPE" = "RRL_e" ];then
  # ! ignore the ditinction between first-overtone RRCs and second-overtone RRe !
  FinalType="RRC"
 elif [ "$ML_CLASSIFIER_TYPE" = "EB_EC" ];then
  # Rename ML types into GCVS types
  FinalType="EW"
 elif [ "$ML_CLASSIFIER_TYPE" = "EB_ED" ];then
  FinalType="EA"
 elif [ "$ML_CLASSIFIER_TYPE" = "EB_ED" ];then
  FinalType="EA"
 elif [ "$ML_CLASSIFIER_TYPE" = "EB_ESD" ];then
  FinalType="EW"
 else
  FinalType="$ML_CLASSIFIER_TYPE"
 fi
 # convert to uppercase for sonsistency
 FinalType="${FinalType^^}"


 # Add white spaces to have nicely formatted columns in the output
 PADDED_ASASSN_ID=$(printf "%-12s" "$ASASSN_ID")
 PADDED_JMAG=$(printf "%-6s" "$JMAG")
 PADDED_JMAG_ERR=$(printf "%-5s" "$JMAG_ERR")
 PADDED_KMAG=$(printf "%-6s" "$KMAG")
 PADDED_KMAG_ERR=$(printf "%-5s" "$KMAG_ERR")
 PADDED_ML_CLASSIFIER_TYPE=$(printf "%-13s" "$ML_CLASSIFIER_TYPE")
 PADDED_VISUAL_CLASSIFICATION=$(printf "%-8s" "$VISUAL_CLASSIFICATION")
 PADDED_VSXType=$(printf "%-8s" "$VSXType")
 PADDED_FinalType=$(printf "%-8s" "$FinalType")
 PADDED_VSXRA=$(printf "%9.5f" "$VSXRA")
 PADDED_VSXDec=$(printf "%+9.5f" "$VSXDec")
 PADDED_VSXMag=$(printf "%-6s" "$VSXMag")
 # No need to pad VSXName if we print it as the last column
 #PADDED_VSXName=$(printf "%-28s" "$VSXName")
 PADDED_VSXName="$VSXName"
 
  
 # Print results
 echo "ASASSN $PADDED_ASASSN_ID  distance_pc= $DISTANCE $DISTANCE_LOW $DISTANCE_HIGH  g= $ASASSN_MEDIAN_g_MAG  $GAIA_DR3_NAMESTRING  G= $GMAG $GMAG_ERR  MabsG= $EXTINCTION_CORRECTED_ABSGMAG_BESTDIST $EXTINCTION_CORRECTED_ABSGMAG_LOWDIST $EXTINCTION_CORRECTED_ABSGMAG_HIGHDIST  A_G= $EXTINCTION_CORRECTION_GMAG_BESTDIST $GAIA_COLOR_EXCESS_DIST_LOW $EXTINCTION_CORRECTION_GMAG_DIST_HIGH  BP-RP= $GAIA_COLOR $GAIA_COLOR_ERROR  (BP-RP)_0= $GAIA_INTRINSIC_COLOR_BESTDIST $GAIA_INTRINSIC_COLOR_ERR  J= $PADDED_JMAG $PADDED_JMAG_ERR K= $PADDED_KMAG $PADDED_KMAG_ERR  MabsJ= $EXTINCTION_CORRECTED_ABSJMAG_BESTDIST $EXTINCTION_CORRECTED_ABSJMAG_LOWDIST $EXTINCTION_CORRECTED_ABSJMAG_HIGHDIST  A_J= $EXTINCTION_CORRECTION_JMAG_BESTDIST $EXTINCTION_CORRECTION_JMAG_DIST_LOW $EXTINCTION_CORRECTION_JMAG_DIST_HIGH A_K= $EXTINCTION_CORRECTION_KMAG_BESTDIST $EXTINCTION_CORRECTION_KMAG_DIST_LOW $EXTINCTION_CORRECTION_KMAG_DIST_HIGH  FinalType= $PADDED_FinalType MLType= $PADDED_ML_CLASSIFIER_TYPE VisType= $PADDED_VISUAL_CLASSIFICATION VSXType= $PADDED_VSXType VSX_RA_Dec_Name= $PADDED_VSXRA $PADDED_VSXDec $PADDED_VSXName" >> distance_color_type_for_all_stars.txt

 # Terminal output to entertain the user
 tail -n 1 distance_color_type_for_all_stars.txt
 
done 

echo "The results are written to distance_color_type_for_all_stars.txt"
