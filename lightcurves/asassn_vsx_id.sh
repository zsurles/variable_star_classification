#!/usr/bin/env bash

for CLASSFILE in ../downloaded_lightcurves/*_classification.txt ;do
 VSX_ID=$(grep 'vsx_id = ' "$CLASSFILE")
 VSX_ID="${VSX_ID/vsx_id = /}"
 ASASSN_ID=$(grep 'asassn_id = ' "$CLASSFILE")
 ASASSN_ID="${ASASSN_ID/asassn_id = /}"
 echo "$ASASSN_ID    $VSX_ID"
done > asassn_vsx_id.txt

