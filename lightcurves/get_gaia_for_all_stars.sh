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

 # Infrared colors from 2MASS catalog
 # https://vizier.cds.unistra.fr/viz-bin/VizieR-3?-source=II/246/out&-out.max=50&-out.form=HTML%20Table&-out.add=_r&-out.add=_RAJ,_DEJ&-sort=_r&-oc.form=sexa
 # lib/vizquery -site=vizier.cds.unistra.fr -mime=text -source=II/246 -out.max=1 -out.form=mini   -sort=_r -c='278.12175 -33.74589' -c.rs=1.5 -out=2MASS,Jmag,e_Jmag,Hmag,e_Hmag,Kmag,e_Kmag  2>&1 | grep -A3 '2MASS  ' | grep '\.'
 TWOMASS_INFO=$($LIB_VIZQUERY -site=vizier.cds.unistra.fr -mime=text -source=II/246 -out.max=1 -out.form=mini   -sort=_r -c="$VSXRA $VSXDec" -c.rs=1.5 -out=2MASS,Jmag,e_Jmag,Hmag,e_Hmag,Kmag,e_Kmag  2>&1 | grep -A3 '2MASS  ' | grep '\.')
 
 # Print results
 echo "$GAIA_DR3_INFO  $BailerJones_DISTANCE  $TWOMASS_INFO   $VSXType $VSXRA $VSXDec $VSXMag $VSXName"
 
done 

