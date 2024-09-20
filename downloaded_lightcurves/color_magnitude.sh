lib/vizquery -site=vizier.cds.unistra.fr -mime=text -source=I/355/gaiadr3 -out.max=1 -out.form=mini   -sort=_r -c='278.12175 -33.74589' -c.rs=1.5 -out=DR3Name,Gmag,e_Gmag,BPmag,e_BPmag,RPmag,e_RPmag 2>&1 | grep -A3 'DR3Name ' | grep '\.'

lib/vizquery -site=vizier.cds.unistra.fr -mime=text -source=I/352 -out.max=1 -out.form=mini   -sort=_r -c='278.12175 -33.74589' -c.rs=1.5 -out=rgeo,b_rgeo,B_rgeo 2>&1 | grep -A3 'rgeo (pc)' | grep '\.'

lib/vizquery -site=vizier.cds.unistra.fr -mime=text -source=II/246 -out.max=1 -out.form=mini   -sort=_r -c='278.12175 -33.74589' -c.rs=1.5 -out=2MASS,Jmag,e_Jmag,Hmag,e_Hmag,Kmag,e_Kmag  2>&1 | grep -A3 '2MASS  ' | grep '\.'


