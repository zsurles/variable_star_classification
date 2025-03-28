#!/usr/bin/env python3

import sys
from astropy.coordinates import SkyCoord
from astropy import units as u

import mwdust

def main():
    # Check if the correct number of arguments are provided
    if len(sys.argv) != 4:
        print("Usage: ./get_dust.py <RA in degrees> <Dec in degrees> <Distance in parsecs>")
        sys.exit(1)

    try:
        # Read RA, Dec, and distance from command line arguments
        ra = float(sys.argv[1]) * u.deg
        dec = float(sys.argv[2]) * u.deg
        distance = float(sys.argv[3]) * u.pc
    except ValueError:
        print("Invalid input. RA, Dec, and Distance must be numbers.")
        sys.exit(1)

    # Load g band extinction map
    #combined19_g= mwdust.Combined19(filter='Gunn g')
    # Load g band extinction map
    #combined19_r= mwdust.Combined19(filter='Gunn r')
    # Load g band extinction map
    #combined19_i= mwdust.Combined19(filter='Gunn i')
    # Load B band extinction map
    combined19_B= mwdust.Combined19(filter='Landolt B')
    # Load V band extinction map
    combined19_V= mwdust.Combined19(filter='Landolt V')
    # Load R band extinction map
    #combined19_R= mwdust.Combined19(filter='Landolt R')
    # Load I band extinction map
    #combined19_I= mwdust.Combined19(filter='Landolt I')    
    # Load J band extinction map
    combined19_J= mwdust.Combined19(filter='2MASS J')    
    # Load H band extinction map
    #combined19_H= mwdust.Combined19(filter='2MASS H')
    # Load K band extinction map
    combined19_K= mwdust.Combined19(filter='2MASS Ks')
    
    # Create a SkyCoord object with equatorial coordinates (ICRS) and distance
    equatorial_coords = SkyCoord(ra=ra, dec=dec, distance=distance, frame='icrs')

    # Convert to galactic coordinates
    galactic_coords = equatorial_coords.galactic
    
    # Compute g band extinction
    #combined19_g_result= combined19_g(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)
    # Compute r band extinction
    #combined19_r_result= combined19_r(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)
    # Compute i band extinction
    #combined19_i_result= combined19_i(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)
    # Compute B band extinction
    combined19_B_result= combined19_B(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)
    # Compute V band extinction
    combined19_V_result= combined19_V(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)
    # Compute R band extinction
    #combined19_R_result= combined19_R(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)
    # Compute I band extinction
    #combined19_I_result= combined19_I(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)
    # Compute J band extinction
    combined19_J_result= combined19_J(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)
    # Compute H band extinction
    #combined19_H_result= combined19_H(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)
    # Compute K band extinction
    combined19_K_result= combined19_K(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)


    # Compute color excess
    E_BmV= combined19_B_result[0]-combined19_V_result[0]
    # Compute extinction in Gaia bands
    # values from Table 2 of https://ui.adsabs.harvard.edu/abs/2018MNRAS.479L.102C/abstract
    R_G=2.740
    R_BP=3.374
    R_RP=2.035
    #
    A_G=  R_G  * E_BmV
    A_BP= R_BP * E_BmV
    A_RP= R_RP * E_BmV
    #
    E_BPmRP= A_BP - A_RP


    # Print the result
    print("Input parameters:")
    print(f"Galactic Longitude (l): {galactic_coords.l:.6f}")
    print(f"Galactic Latitude (b): {galactic_coords.b:.6f}")
    print(f"Distance: {galactic_coords.distance:.6f}")
    print("---------------------------------------")
    print("Extinction from mwdust.Combined19:")
    print("---------------------------------------")
    #print(f"g band extinction: {combined19_g_result[0]:.3f} mag")
    #print(f"r band extinction: {combined19_r_result[0]:.3f} mag")
    #print(f"i band extinction: {combined19_i_result[0]:.3f} mag")
    #print("---------------------------------------")
    print(f"B band extinction: {combined19_B_result[0]:.3f} mag")
    print(f"V band extinction: {combined19_V_result[0]:.3f} mag")
    #print(f"R band extinction: {combined19_R_result[0]:.3f} mag")
    #print(f"I band extinction: {combined19_I_result[0]:.3f} mag")
    #print("---------------------------------------")
    print(f"J band extinction: {combined19_J_result[0]:.3f} mag")
    #print(f"H band extinction: {combined19_H_result[0]:.3f} mag")
    print(f"K band extinction: {combined19_K_result[0]:.3f} mag")
    print("---------------------------------------")
    print(f"E(B-V): {E_BmV:.3f} mag")
    print("converted to extinction in Gaia bands following Casagrande & VandenBerg (2018MNRAS.479L.102C):")
    print(f"G band extinction:  {A_G:.3f} mag")
    print(f"BP band extinction: {A_BP:.3f} mag")
    print(f"RP band extinction: {A_RP:.3f} mag")
    print(f"E(BP-RP): {E_BPmRP:.3f} mag")

if __name__ == "__main__":
    main()
