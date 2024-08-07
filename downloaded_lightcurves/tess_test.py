#!/usr/bin/env python

import lightkurve as lk  # Importing the lightkurve library for working with TESS data
from photutils.centroids import centroid_com  # Importing function for calculating centroid
from photutils.aperture import CircularAperture, CircularAnnulus, aperture_photometry  # Importing photometry functions
from astropy.stats import sigma_clipped_stats  # Importing sigma-clipped statistics
from lightkurve import LightCurve  # Importing LightCurve class
import numpy as np  # Importing numpy for numerical operations
from astropy.visualization import simple_norm  # Importing visualization tools
from astropy.time import Time  # Importing Time class for handling time conversions
import warnings  # Importing warnings to suppress specific warnings

# Suppress specific warnings from astropy.stats.sigma_clipping
warnings.filterwarnings('ignore', message='Input data contains invalid values', category=UserWarning, module='astropy.stats.sigma_clipping')

# Lightkurve cuts on image quality flags
qualitycuts = 'default'

from astropy.coordinates import SkyCoord  # Importing SkyCoord class for coordinate conversions
from astropy import units as u  # Importing units from astropy

# Switch to enable or disable writing of all lightcurves
WRITE_ALL_LIGHTCURVES = False

# Switch to enable or disable writing of the best lightcurve in the units of electrons/s
WRITE_BEST_LIGHTCURVE_ELECTRONS = False

# Switch to enable or disable writing of the best lightcurve in the units of magnitude
WRITE_BEST_LIGHTCURVE_MAGNITUDES = True


def radec_to_pixel(tpf, target_radec):
    """
    Convert RA/Dec coordinates to pixel coordinates in the TPF.

    Parameters:
    tpf (TargetPixelFile): The target pixel file object.
    target_radec (str): RA/Dec coordinates of the target.

    Returns:
    tuple: Pixel coordinates (x, y).
    """
    coord = SkyCoord.from_name(target_radec)  # Create a SkyCoord object from the RA/Dec string
    pixel = tpf.wcs.world_to_pixel(coord)  # Convert to pixel coordinates using WCS
    return pixel[0].item(), pixel[1].item()  # Return pixel coordinates as a tuple

def calculate_tpf_centroid(tpf, initial_position, aperture_radius=1.5):
    """
    Calculate the centroid of a stacked image from a TPF using the center of mass method.

    Parameters:
    tpf (TargetPixelFile): The target pixel file object.
    initial_position (tuple): Initial guess for the position of the source (x, y).
    aperture_radius (float): Radius of the circular aperture for the initial guess.

    Returns:
    tuple: Centroid position (x_centroid, y_centroid).
    """
    stacked_image = np.nanmedian(tpf.flux, axis=0)  # Stack all cadences to create a median image
    initial_position = np.array(initial_position)  # Ensure initial_position is an array
    aperture = CircularAperture(initial_position, r=aperture_radius)  # Create an aperture mask
    mask = aperture.to_mask(method='center')  # Create a mask from the aperture
    mask_image = mask.to_image(stacked_image.shape)  # Convert mask to image
    sub_image = stacked_image * mask_image  # Extract the sub-image for centroid calculation
    y_centroid_sub, x_centroid_sub = centroid_com(sub_image)  # Calculate the centroid in the sub-image
    return x_centroid_sub, y_centroid_sub  # Return the centroid

def shots_sourcextractor_style_background_estimate_for_1d_data(annulus_data_1d):
    """
    Estimate the background value and standard deviation for 1D annulus data.

    Parameters:
    annulus_data_1d (array): 1D array of annulus data.

    Returns:
    tuple: Background value (median) and standard deviation.
    """
    if len(annulus_data_1d) == 0 or np.all(np.isnan(annulus_data_1d)):
        return np.nan, np.nan  # Return NaN if no valid data
    mean, median, std = sigma_clipped_stats(annulus_data_1d, sigma=3.0, cenfunc='median', stdfunc='mad_std')  # Perform sigma-clipped stats
    return median, std  # Return median and standard deviation

def custom_aperture_photometry_to_lightcurve(tpf, object_position, aperture_radius, annulus_inner_radius, annulus_outer_radius):
    """
    Perform aperture photometry on a target pixel file (TPF) and return a LightCurve object.

    Parameters:
    tpf (TargetPixelFile object): The target pixel file object.
    object_position (tuple): The position of the target (x, y) in pixels.
    aperture_radius (float): Radius of the circular aperture.
    annulus_inner_radius (float): Inner radius of the annular aperture.
    annulus_outer_radius (float): Outer radius of the annular aperture.

    Returns:
    LightCurve object: LightCurve object with the flux values for each cadence.
    """
    
    # Check that the input object position is reasonable
    if not np.all(np.isfinite(object_position)) :
        print("The input pixel position is not a finite number! -- skipping sector " + str(tpf_target.sector) + ' custom_aperture_photometry_to_lightcurve()' )
        return None, None, None

    # Check that the Targe Pixel File (cutout) is not too close to the frame edge
    if tpf_target.column < 44+annulus_outer_radius or tpf_target.column  > 2093-annulus_outer_radius :
        print("Too close to frame edge: tpf_target.column= " + str(tpf_target.column) + ' -- skipping sector ' + str(tpf_target.sector) + ' custom_aperture_photometry_to_lightcurve()')
        return None, None, None
    
    if tpf_target.row < annulus_outer_radius or tpf_target.row > 2049-annulus_outer_radius :
        print("Too close to frame edge: tpf_target.row= " + str(tpf_target.row) + ' -- skipping sector ' + str(tpf_target.sector) + ' custom_aperture_photometry_to_lightcurve()')
        return None, None, None

    flux_values = []
    flux_values_raw = []
    flux_values_bkg_per_pix = []
    flux_values_bkg_std_per_aperture = []
    time_values = tpf.time  # Assuming 'time' attribute is present in tpf

    # Define apertures
    aperture = CircularAperture(object_position, r=aperture_radius)
    annulus_aperture = CircularAnnulus(object_position, r_in=annulus_inner_radius, r_out=annulus_outer_radius)
    sources_mask = tpf.create_threshold_mask(threshold=0.001, reference_pixel=None)  # Create a mask for sources

    for cadence in tpf.flux:
        phot_table = aperture_photometry(cadence, aperture)  # Perform aperture photometry
        cadence[sources_mask] = np.nan  # Assign NaN values to masked pixels for background estimation

        annulus_masks = annulus_aperture.to_mask(method='center')  # Create annulus masks
        annulus_data = annulus_masks.multiply(cadence)  # Multiply masks with cadence
        annulus_data_1d = annulus_data[annulus_masks.data > 0]  # Extract 1D annulus data

        bkg_value, std = shots_sourcextractor_style_background_estimate_for_1d_data(annulus_data_1d)  # Estimate background

        bkg_flux = bkg_value * aperture.area  # Calculate background flux
        bkg_std_per_aperture = std * aperture.area  # Calculate background standard deviation per aperture
        final_flux_raw = phot_table['aperture_sum']  # Extract raw flux
        final_flux = phot_table['aperture_sum'] - bkg_flux  # Subtract background from flux

        if final_flux[0] <= 0.0:
            final_flux[0] = np.nan  # Assign NaN to negative or zero background-subtracted flux values

        if final_flux_raw[0].value <= 50.0:
            final_flux[0] = np.nan  # Assign NaN to suspiciously low raw flux values

        flux_values.append(final_flux[0])  # Append final flux value
        flux_values_raw.append(final_flux_raw[0])  # Append raw flux value
        flux_values_bkg_per_pix.append(bkg_value)  # Append background value per pixel
        flux_values_bkg_std_per_aperture.append(bkg_std_per_aperture)  # Append background standard deviation per aperture

    flux_values_unit = flux_values[0].unit  # Extract units from flux values
    flux_values = np.array([f.value for f in flux_values]) * flux_values_unit  # Convert flux values to array with units
    flux_values_raw = np.array([f.value for f in flux_values_raw]) * flux_values_unit  # Convert raw flux values to array with units
    flux_values_bkg_per_pix = np.array([f.value for f in flux_values_bkg_per_pix])  # Convert background values to array

    bkg_median, bkg_std = shots_sourcextractor_style_background_estimate_for_1d_data(flux_values_bkg_per_pix)  # Estimate background
    bkg_threshold = bkg_median + 3 * bkg_std  # Calculate background threshold

    high_bkg_mask = flux_values_bkg_per_pix > bkg_threshold  # Create mask for high background values
    flux_values[high_bkg_mask] = np.nan  # Assign NaN to high background flux values
    flux_values_raw[high_bkg_mask] = np.nan  # Assign NaN to high background raw flux values

    lc_bkg_subtracted = LightCurve(time=time_values, flux=flux_values, flux_err=flux_values_bkg_std_per_aperture)  # Create LightCurve for background-subtracted flux
    lc_raw = LightCurve(time=time_values, flux=flux_values_raw, flux_err=flux_values_bkg_std_per_aperture)  # Create LightCurve for raw flux
    lc_bkg_per_pix = LightCurve(time=time_values, flux=flux_values_bkg_per_pix)  # Create LightCurve for background per pixel

    return lc_bkg_subtracted, lc_raw, lc_bkg_per_pix  # Return LightCurve objects

def convert_flux_to_mag(time, flux, flux_err):
    """
    Convert flux to magnitudes.

    Parameters:
    time (array): Time values.
    flux (array): Flux values.
    flux_err (array): Flux error values.

    Returns:
    array: Time, magnitude, magnitude error.
    """
    flux = flux.value  # Remove units for log10 calculation
    flux_err = flux_err.value  # Remove units for log10 calculation
    mag = 20.44 - 2.5 * np.log10(flux)  # Convert flux to magnitude
    mag_err = -2.5 * np.log10((flux - flux_err) / flux)  # Calculate magnitude error
    #time_jd = 2457000.0 + time.jd  # Convert TESS JD to regular JD
    time_jd = time.jd
    return time_jd, mag, mag_err  # Return time, magnitude, and magnitude error

# Define target list
target_list = [
#    ('GD 71', '05:52:27.5 +15:53:17')
#    ('274879224913', '64.52258 -75.78525')
#    ('335008175967', '64.95854 -15.98431')
#    ('369368371268', '70.43975 -18.16211')
#    ('377957946792', '73.51246 2.40304'),
#    ('377957946930', '73.60091 2.40795'),
#    ('395137351153', '64.506 -3.71289'),
#    ('51539924432', '69.11449 41.19133'),
#    ('592705522133', '69.8755 -32.55183'),
#    ('618475876236', '69.19122 -69.63575'),
#    ('661427630085', '73.05292 -56.34647'),
#    ('661428739016', '73.54704 9.8306'),
#    ('661428824160', '71.65958 30.98917'),
#    ('661428856578', '67.1465 39.38411')
#('661428824160', '71.65958 30.98917'),
#('661428856578', '67.1465 39.38411'),
#('661428889612', '64.12098 44.73159'),
#('661428964531', '68.95677 80.24478'),
#('111669775499', '76.621 40.56614')
#
#('257699152135', '77.21642 -0.04306'),
#('283468390453', '81.80858 8.78927'),
#('300647737742', '79.31067 -11.69956'),
#('300648818343', '79.2273 -1.44305'),
#('317828178859', '78.92375 -42.33008'),
#('317828288727', '76.40525 11.33753'),
('317828483239', '79.84188 -18.54715'),
('34360185365', '78.35631 79.7909')
]

stored_lc_targets = []  # List to store target lightcurves
stored_lc_aperture = []  # List to store aperture lightcurves

# Define aperture and annulus radii
aperture_radii = [1.5, 2.0, 2.5]
annulus_radii_pairs = [(3.5, 10.5), (3.5, 7.5), (5.5, 10.5)]

for target_name, target_radec in target_list:
    print(f"Target Name: {target_name}")
    print(f"Target RA/DEC: {target_radec}")
    search_lc = lk.search_tesscut(target_radec)  # Search TESSCut for the target
    print(search_lc)

    lightcurves_input = {}  # Dictionary to store lightcurves with rounded centroids
    lightcurves_calculated = {}  # Dictionary to store lightcurves with calculated centroids

    for search_result in search_lc:
        tpf_target = search_result.download(cutout_size=24, quality_bitmask=qualitycuts)  # Download the target pixel file
        if tpf_target is None:
            continue

        # Initial check that the Targe Pixel File (cutout) is not too close to the frame edge
        if tpf_target.column < 44+10 or tpf_target.column  > 2093-10 :
            print("Too close to frame edge: tpf_target.column= " + str(tpf_target.column) + ' -- skipping sector ' + str(tpf_target.sector) + ' (main script)')
            continue
        if tpf_target.row < 10 or tpf_target.row > 2049-10 :
            print("Too close to frame edge: tpf_target.row= " + str(tpf_target.row) + ' -- skipping sector ' + str(tpf_target.sector) + ' (main script)')
            continue

        initial_x, initial_y = radec_to_pixel(tpf_target, target_radec)  # Convert RA/Dec to pixel coordinates
        # Check that the input object position is reasonable
        if not np.all(np.isfinite( (initial_x, initial_y) )) :
            print("The input pixel position is not a finite number! -- skipping sector " + str(tpf_target.sector) + ' (main script)' )
            continue

        x_centroid_calc, y_centroid_calc = calculate_tpf_centroid(tpf_target, (initial_x, initial_y))  # Calculate centroid
        # Check that the input object position is reasonable
        if not np.all(np.isfinite( (x_centroid_calc, y_centroid_calc) )) :
            print("The calculated pixel position is not a finite number! -- skipping sector " + str(tpf_target.sector) + ' (main script)' )
            continue


        for r in aperture_radii:
            for ann_inner, ann_outer in annulus_radii_pairs:
                # Perform aperture photometry placing the aperture at the source position derived from the input celestial coordinates
                lc_bkg_subtracted_input, lc_raw_input, lc_bkg_per_pix_input = custom_aperture_photometry_to_lightcurve(
                    tpf_target, (initial_x, initial_y), r, ann_inner, ann_outer)
                
                # Check if something went wrong during the lightcurve creation
                # (like target too close to the frame edge)
                if lc_bkg_subtracted_input is None:
                    continue
                
                key = (r, ann_inner, ann_outer, 'rounded')
                if key not in lightcurves_input:
                    lightcurves_input[key] = lc_bkg_subtracted_input
                else:
                    lightcurves_input[key] = lightcurves_input[key].append(lc_bkg_subtracted_input)

                # Perform aperture photometry for calculated centroid
                lc_bkg_subtracted_calc, lc_raw_calc, lc_bkg_per_pix_calc = custom_aperture_photometry_to_lightcurve(
                    tpf_target, (x_centroid_calc, y_centroid_calc), r, ann_inner, ann_outer)
                
                if lc_bkg_subtracted_calc is None:
                    continue
                
                key = (r, ann_inner, ann_outer, 'calculated')
                if key not in lightcurves_calculated:
                    lightcurves_calculated[key] = lc_bkg_subtracted_calc
                else:
                    lightcurves_calculated[key] = lightcurves_calculated[key].append(lc_bkg_subtracted_calc)

    def mad(data, axis=None):
        """
        Calculate Median Absolute Deviation (MAD).

        Parameters:
        data (array): Data values.
        axis (int): Axis along which the MAD is calculated.

        Returns:
        float: MAD value.
        """
        median = np.nanmedian(data, axis=axis)  # Calculate median
        mad = np.nanmedian(np.abs(data - median), axis=axis)  # Calculate MAD
        return mad  # Return MAD value

    min_mad_value = float('inf')  # Initialize minimum MAD value
    best_lightcurve = None  # Initialize best lightcurve
    best_description = ""  # Initialize description for the best lightcurve

    # Evaluate lightcurves with rounded centroids
    for key, lc in lightcurves_input.items():
        r, ann_inner, ann_outer, method = key
        lc = lc.remove_nans()  # Remove NaN values
        mad_value = mad(lc.flux)  # Calculate MAD value
        print(f'MAD for {method} centroid, aperture radius {r}, annulus {ann_inner}-{ann_outer}: {mad_value}')
        if mad_value < min_mad_value:
            min_mad_value = mad_value
            best_lightcurve = lc
            best_description = f'{method} Centroid, Aperture Radius: {r}, Annulus Inner Radius: {ann_inner}, Annulus Outer Radius: {ann_outer}'
        title = f"{target_name}_r{r}_ann{ann_inner}-{ann_outer}_{method}"
        output_filename_csv = title.replace(" ", "_") + '_TESS_lk_circap.csv'
        if WRITE_ALL_LIGHTCURVES:
            lc.to_csv(output_filename_csv, overwrite=True)
            print(f'Writing file {output_filename_csv}')

    # Evaluate lightcurves with calculated centroids
    for key, lc in lightcurves_calculated.items():
        r, ann_inner, ann_outer, method = key
        lc = lc.remove_nans()  # Remove NaN values
        mad_value = mad(lc.flux)  # Calculate MAD value
        print(f'MAD for {method} centroid, aperture radius {r}, annulus {ann_inner}-{ann_outer}: {mad_value}')
        if mad_value < min_mad_value:
            min_mad_value = mad_value
            best_lightcurve = lc
            best_description = f'{method} Centroid, Aperture Radius: {r}, Annulus Inner Radius: {ann_inner}, Annulus Outer Radius: {ann_outer}'
        title = f"{target_name}_r{r}_ann{ann_inner}-{ann_outer}_{method}"
        output_filename_csv = title.replace(" ", "_") + '_TESS_lk_circap.csv'
        if WRITE_ALL_LIGHTCURVES:
            lc.to_csv(output_filename_csv, overwrite=True)
            print(f'Writing file {output_filename_csv}')

    # Save the best lightcurve
    if best_lightcurve is not None:
        print(f'Best lightcurve: {best_description}')
        
        if WRITE_BEST_LIGHTCURVE_ELECTRONS:
            best_output_filename_csv = f"{target_name.replace(' ', '_')}_best_TESS_lightcurve.csv"
            best_lightcurve.to_csv(best_output_filename_csv, overwrite=True)
            print(f'Writing best lightcurve to file {best_output_filename_csv}')

        if WRITE_BEST_LIGHTCURVE_MAGNITUDES:
            # Convert the best lightcurve to magnitudes and write to a new file
            time_jd, mag, mag_err = convert_flux_to_mag(best_lightcurve.time, best_lightcurve.flux, best_lightcurve.flux_err)
            best_lightcurve_mag = np.column_stack((time_jd, mag, mag_err))
            best_mag_output_filename = f"{target_name.replace(' ', '_')}_best_lightcurve_mag.dat"
            np.savetxt(best_mag_output_filename, best_lightcurve_mag, delimiter=' ', fmt='%.6f %.6f %.6f')
            print(f'Writing best lightcurve (magnitudes) to file {best_mag_output_filename}')
