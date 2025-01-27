#!/usr/bin/env bash

folder_path="/Users/zoesurles/Desktop/variable_star_classification/downloaded_lightcurves"

output_file="./g_band_magnitude_information.txt"

echo -e "ASASSN ID\tMEAN VALUE\tMEDIAN VALUE" > "$output_file"

for file in "$folder_path"/*.txt; do
    # Skip files with "_classification" in the name
    if [[ $(basename "$file") == *_classification.txt ]]; then
        continue
    fi
    if [[ $(basename "$file") == *_badpoints.txt ]]; then
        continue
    fi
    if [[ $(basename "$file") == *_edit.txt ]]; then
        continue
    fi

    # Extract the ID number from the file name
    id_number=$(basename "$file" .txt)
    
    # Check if the file exists and has content
    if [[ -s $file ]]; then
        # Extract the second column (Magnitude), calculate mean and median using awk
        stats=$(awk '
        {
            magnitudes[NR] = $2;
            sum += $2;
        }
        END {
            mean = sum / NR;

            # Sort the magnitudes array for median calculation
            asort(magnitudes);
            if (NR % 2 == 1) {
                median = magnitudes[int(NR/2) + 1];
            } else {
                median = (magnitudes[int(NR/2)] + magnitudes[int(NR/2) + 1]) / 2;
            }

            printf "%.6f\t%.6f", mean, median;
        }' "$file")

        # Append results to the output file
        echo -e "$id_number\t$stats" >> "$output_file"
    else
        echo "Skipping empty file: $file"
    fi
done

echo "Summary saved to $output_file"
