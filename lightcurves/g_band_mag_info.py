import os
import numpy as np
import re  # regular expressions

# Initial path specified by Zoe
initial_folder_path = "/Users/zoesurles/Desktop/variable_star_classification/downloaded_lightcurves"

# Check if the initial path exists
if os.path.exists(initial_folder_path):
    zoes_folder_path = initial_folder_path
else:
    # Get the directory where the script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Construct the path to ../downloaded_lightcurves relative to the script location
    alternative_path = os.path.join(script_dir, "..", "downloaded_lightcurves")
    
    # Check if the alternative path exists
    if os.path.exists(alternative_path):
        zoes_folder_path = alternative_path
    else:
        raise FileNotFoundError(f"Neither {initial_folder_path} nor {alternative_path} exist")

output_file = "./g_band_magnitude_information.txt"

with open(output_file, "w") as f:
    #f.write("ASASSN ID\tMEAN VALUE\tMEDIAN VALUE\n")
    f.write(f"{'MEAN':>6} {'MEDIAN':>6} {'ASASSN_ID':>12}\n")

# Process each file in the folder
for file_name in os.listdir(zoes_folder_path):
    file_path = os.path.join(zoes_folder_path, file_name)

    # Skip files that are not ASASSNID.txt
    if (
        "_classification.txt" in file_name
        or "combined" in file_name
        or "_badpoints.txt" in file_name
        or "_edit.txt" in file_name
        or ".html" in file_name
        or ".csv" in file_name
        or ".dat" in file_name
        or ".py" in file_name
        or ".sh" in file_name
    ):
        continue

    # Check if the filename matches the pattern of only numbers followed by .txt
    if not re.match(r'^\d+\.txt$', file_name):
        continue

    # Extract the ASASSN ID from the file name
    id_number, ext = os.path.splitext(file_name)

    # Check that the file is not empty
    if os.path.isfile(file_path) and os.path.getsize(file_path) > 0:
        # Read the file and extract magnitudes from the second column
        try:
            magnitudes = []
            with open(file_path, "r") as f:
                for line in f:
                    try:
                        parts = line.split()
                        if len(parts) > 1:  # Ensure the line has enough columns
                            magnitudes.append(float(parts[1]))
                    except ValueError:
                        continue  # Skip lines with invalid data

            # Calculate mean and median
            if magnitudes:
                mean_value = np.mean(magnitudes)
                median_value = np.median(magnitudes)

                # Append results to the output file
                with open(output_file, "a") as f:
                    #f.write(f"{id_number}\t{mean_value:.6f}\t{median_value:.6f}\n")
                    f.write(f"{mean_value:6.3f} {median_value:6.3f} {id_number:>12}\n")
            else:
                print(f"No valid data in file: {file_name}")
        except Exception as e:
            print(f"Error processing file {file_name}: {e}")
    else:
        print(f"Skipping empty file: {file_name}")

print(f"Summary saved to {output_file}")



