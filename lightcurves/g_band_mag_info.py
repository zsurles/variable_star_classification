import os
import numpy as np

folder_path = "/Users/zoesurles/Desktop/variable_star_classification/downloaded_lightcurves"
output_file = "./g_band_magnitude_information.txt"

with open(output_file, "w") as f:
    f.write("ASASSN ID\tMEAN VALUE\tMEDIAN VALUE\n")

# Process each file in the folder
for file_name in os.listdir(folder_path):
    file_path = os.path.join(folder_path, file_name)

    # Skip files that match the exclusion criteria
    if (
        "_classification.txt" in file_name
        or "_badpoints.txt" in file_name
        or "_edit.txt" in file_name
        or ".csv" in file_name
        or "_best_lightcurve_mag.dat" in file_name
    ):
        continue

    # Extract the ID number (file name without extension)
    id_number, ext = os.path.splitext(file_name)

    # Check if the file is not empty
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
                    f.write(f"{id_number}\t{mean_value:.6f}\t{median_value:.6f}\n")
            else:
                print(f"No valid data in file: {file_name}")
        except Exception as e:
            print(f"Error processing file {file_name}: {e}")
    else:
        print(f"Skipping empty file: {file_name}")

print(f"Summary saved to {output_file}")



