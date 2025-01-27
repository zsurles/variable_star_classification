import os
import numpy as np
import csv

zoes_folder_path = "/Users/zoesurles/Desktop/variable_star_classification/downloaded_lightcurves"
output_file = "./g_band_magnitude_information.csv"

# Open the output file and set up the CSV writer
with open(output_file, "w", newline="") as f:
    csv_writer = csv.writer(f)
    # Write the header row
    csv_writer.writerow(["ASASSN ID", "MEAN VALUE", "MEDIAN VALUE"])

# Process each file in the folder
for file_name in os.listdir(zoes_folder_path):
    file_path = os.path.join(zoes_folder_path, file_name)

    # Skip files that are not ASASSNID.txt
    if (
        "_classification.txt" in file_name
        or "_badpoints.txt" in file_name
        or "_edit.txt" in file_name
        or ".csv" in file_name
        or ".dat" in file_name
        or ".py" in file_name
        or ".sh" in file_name
    ):
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

                # Append results to the CSV file
                with open(output_file, "a", newline="") as f:
                    csv_writer = csv.writer(f)
                    csv_writer.writerow([id_number, f"{mean_value:.6f}", f"{median_value:.6f}"])
            else:
                print(f"No valid data in file: {file_name}")
        except Exception as e:
            print(f"Error processing file {file_name}: {e}")
    else:
        print(f"Skipping empty file: {file_name}")

print(f"Summary saved to {output_file}")
