#!/usr/bin/env python3

import numpy as np

import upsilon

# Load a classification model.
# (takes time, do only once if processing multiple lcs)
rf_model = upsilon.load_rf_model()


############# Read input lc data #############
# Read the input lightcurve file
f = open('lightcurve.dat', 'r')
data = np.loadtxt(f, dtype={'names': ('JD', 'mag', 'err'),'formats': ('float64', 'float64', 'float64')})
f.close()

# Split it into three arrays
date=data['JD']
mag=data['mag']
err=data['err']

# Sigma-clip the input lightcurve
date, mag, err = upsilon.utils.sigma_clipping(date, mag, err,  threshold=3, iteration=1)

############# Extract lightcurve features #############
e_features = upsilon.ExtractFeatures(date, mag, err)
e_features.run()
features = e_features.get_features()

############# Classify #############
# Classify the light curve
label, probability, flag = upsilon.predict(rf_model, features)

# Print results
##print label, probability, flag
#print "\n\n######### Classification results #########\n"
#print "flag = ",flag," (0 - classification success, 1 - suspicious period)"
#print "class = ",label
#print "class_probability = ",probability
#
#print "\n\n######### Lightcurve features #########\n"

print("\n\n######### Classification results #########\n")
print("flag = " + str(flag) + " (0 - classification success, 1 - suspicious period)")
print("class = " + str(label) )
print("class_probability = " + str(probability) )
print("\n\n######### Lightcurve features #########\n")

for feature in features:
  print( str(feature) + " = " + str(features[feature]) )
#  print feature," = ",features[feature]
  

