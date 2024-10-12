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

grep -v 'Star Type' rrlyr_vsx_clean2_magnitude_filtered.txt | while read VSXType VSXRA VSXDec VSXMag VSXName ;do

 # Gaia optical magnitudes 
 # https://vizier.cds.unistra.fr/viz-bin/VizieR-3?-source=I/355/gaiadr3&-out.max=50&-out.form=HTML%20Table&-out.add=_r&-out.add=_RAJ,_DEJ&-sort=_r&-oc.form=sexa
 #lib/vizquery -site=vizier.cds.unistra.fr -mime=text -source=I/355/gaiadr3 -out.max=1 -out.form=mini   -sort=_r -c='278.12175 -33.74589' -c.rs=1.5 -out=DR3Name,Gmag,e_Gmag,BPmag,e_BPmag,RPmag,e_RPmag 2>&1 | grep -A3 'DR3Name ' | grep '\.'
 # Example output:
 # Gaia DR3 2875539776437822592 12.868528  0.011965 13.166146  0.038479 12.473855  0.024048
 GAIA_DR3_INFO=$($LIB_VIZQUERY -site=vizier.cds.unistra.fr -mime=text -source=I/355/gaiadr3 -out.max=1 -out.form=mini   -sort=_r -c="$VSXRA $VSXDec" -c.rs=1.5 -out=DR3Name,Gmag,e_Gmag,BPmag,e_BPmag,RPmag,e_RPmag 2>&1 | grep -A3 'DR3Name ' | grep '\.')
 #lib/vizquery -site=vizier.cds.unistra.fr -mime=text -source=I/352 -out.max=1 -out.form=mini   -sort=_r -c='278.12175 -33.74589' -c.rs=1.5 -out=rgeo,b_rgeo,B_rgeo 2>&1 | grep -A3 'rgeo (pc)' | grep '\.'
 
 
 # Distance from Bailer-Jones+, 2021
 # http://vizier.cds.unistra.fr/viz-bin/VizieR?-source=I/352&-to=3
 # lib/vizquery -site=vizier.cds.unistra.fr -mime=text -source=I/352 -out.max=1 -out.form=mini   -sort=_r -c='278.12175 -33.74589' -c.rs=1.5 -out=rgeo,b_rgeo,B_rgeo 2>&1 | grep -A3 'rgeo (pc)' | grep '\.'
 BailerJones_DISTANCE=$($LIB_VIZQUERY -site=vizier.cds.unistra.fr -mime=text -source=I/352 -out.max=1 -out.form=mini   -sort=_r -c="$VSXRA $VSXDec" -c.rs=1.5 -out=rgeo,b_rgeo,B_rgeo 2>&1 | grep -A3 'rgeo (pc)' | grep '\.')
 DISTANCE=$(echo "$BailerJones_DISTANCE" | awk '{print $1}')

 # Infrared colors from 2MASS catalog
 # https://vizier.cds.unistra.fr/viz-bin/VizieR-3?-source=II/246/out&-out.max=50&-out.form=HTML%20Table&-out.add=_r&-out.add=_RAJ,_DEJ&-sort=_r&-oc.form=sexa
 # lib/vizquery -site=vizier.cds.unistra.fr -mime=text -source=II/246 -out.max=1 -out.form=mini   -sort=_r -c='278.12175 -33.74589' -c.rs=1.5 -out=2MASS,Jmag,e_Jmag,Hmag,e_Hmag,Kmag,e_Kmag  2>&1 | grep -A3 '2MASS  ' | grep '\.'
 TWOMASS_INFO=$($LIB_VIZQUERY -site=vizier.cds.unistra.fr -mime=text -source=II/246 -out.max=1 -out.form=mini   -sort=_r -c="$VSXRA $VSXDec" -c.rs=1.5 -out=2MASS,Jmag,e_Jmag,Hmag,e_Hmag,Kmag,e_Kmag  2>&1 | grep -A3 '2MASS  ' | grep '\.')
 JMAG=$(echo "$TWOMASS_INFO" | awk '{print $2}')
 HMAG=$(echo "$TWOMASS_INFO" | awk '{print $4}')
 KMAG=$(echo "$TWOMASS_INFO" | awk '{print $6}')
 
 # Get extinction information
 #EXTINCTION_SCRIPT_OUTPUT=$(./get_dust.py "$VSXRA" "$VSXDec" "$DISTANCE")
 #A_JMAG=$(echo "$EXTINCTION_SCRIPT_OUTPUT" | grep )
 
 GET_DUST_OUTPUT=$(./get_dust.py "$VSXRA" "$VSXDec" "$DISTANCE") 
 EXTINCTION_CORRECTION_JMAG_BESTDIST=$(echo "$GET_DUST_OUTPUT" | grep 'J band extinction' | awk '{print $4}')
 EXTINCTION_CORRECTION_HMAG_BESTDIST=$(echo "$GET_DUST_OUTPUT" | grep 'H band extinction' | awk '{print $4}')
 EXTINCTION_CORRECTION_KMAG_BESTDIST=$(echo "$GET_DUST_OUTPUT" | grep 'K band extinction' | awk '{print $4}')
 #EXTINCTION_CORRECTED_JMAG_BESTDIST=$(echo "$JMAG" "$EXTINCTION_CORRECTION_JMAG_BESTDIST" | awk '{printf "%6.3f\n", $1 - $2}')
 #EXTINCTION_CORRECTED_HMAG_BESTDIST=$(echo "$HMAG" "$EXTINCTION_CORRECTION_HMAG_BESTDIST" | awk '{printf "%6.3f\n", $1 - $2}')
 #EXTINCTION_CORRECTED_KMAG_BESTDIST=$(echo "$KMAG" "$EXTINCTION_CORRECTION_KMAG_BESTDIST" | awk '{printf "%6.3f\n", $1 - $2}')
 
 # M = m + 5 - 5 * log10(r_pc) - A
 # where M is the absolute magnitude
 # m is the apparent magnitude
 # r_pc is the distance in pc
 # A is the extinciton in magnitudes
 #echo "100" | awk '{print log($1)/log(10)}'
 EXTINCTION_CORRECTED_ABSJMAG_BESTDIST=$(echo "$JMAG" "$DISTANCE" "$EXTINCTION_CORRECTION_JMAG_BESTDIST" | awk '{printf "%+7.3f", $1 + 5 - 5 * log($2)/log(10) - $3 }')


 # Get ASASSN ID from VSX name
 # '$' here is the mark that VSXName should be at the end of the line
 ASASSN_ID=$(grep "  $VSXName$" asassn_vsx_id.txt | awk '{print $1}')
  
 # Print results
 echo "$ASASSN_ID   $GAIA_DR3_INFO  $BailerJones_DISTANCE  $TWOMASS_INFO   $VSXType $VSXRA $VSXDec $VSXMag $VSXName"

 echo "$EXTINCTION_CORRECTED_ABSJMAG_BESTDIST   $EXTINCTION_CORRECTED_JMAG_BESTDIST  $EXTINCTION_CORRECTED_HMAG_BESTDIST $EXTINCTION_CORRECTED_KMAG_BESTDIST  $ASASSN_ID   $VSXName"
 
done 

