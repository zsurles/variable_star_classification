#!/usr/bin/env python3

import sys
from astropy.coordinates import SkyCoord
from astropy import units as u

import mwdust

def main():
    # Check if the correct number of arguments are provided
    if len(sys.argv) != 4:
        print("Usage: python3 convert_coords.py <RA in degrees> <Dec in degrees> <Distance in parsecs>")
        sys.exit(1)

    try:
        # Read RA, Dec, and distance from command line arguments
        ra = float(sys.argv[1]) * u.deg
        dec = float(sys.argv[2]) * u.deg
        distance = float(sys.argv[3]) * u.pc
    except ValueError:
        print("Invalid input. RA, Dec, and Distance must be numbers.")
        sys.exit(1)

    # Load J band extinction map
    combined19_J= mwdust.Combined19(filter='2MASS J')
    
    # Load K band extinction map
    combined19_K= mwdust.Combined19(filter='2MASS Ks')
    
    # Create a SkyCoord object with equatorial coordinates (ICRS) and distance
    equatorial_coords = SkyCoord(ra=ra, dec=dec, distance=distance, frame='icrs')

    # Convert to galactic coordinates
    galactic_coords = equatorial_coords.galactic
    
    # Compute J band extinction
    combined19_J_result= combined19_J(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)

    # Compute K band extinction
    combined19_K_result= combined19_K(equatorial_coords.galactic.l.value,equatorial_coords.galactic.b.value,galactic_coords.distance.value/1000)

    # Print the result
    print(f"Galactic Longitude (l): {galactic_coords.l:.6f}")
    print(f"Galactic Latitude (b): {galactic_coords.b:.6f}")
    print(f"Distance: {galactic_coords.distance:.6f}")
    print(f"J band extinction at: {combined19_J_result[0]:.3f}")
    print(f"K band extinction at: {combined19_K_result[0]:.3f}")

if __name__ == "__main__":
    main()
