if [ -f "asassn_id_only.txt" ]; then
    while IFS= read -r line; do
        echo "Line: $line"
        /Users/zoesurles/Desktop/vsc_vast/vast/lib/ls_compute_periodogram ~/Desktop/variable_star_classification/downloaded_lightcurves/$line.txt 2 0.1 0.05 | grep 'FAP' | awk '{print $1}' >> frequencies.txt
    done < "asassn_id_only.txt"
else
    echo "File not found: asassn_id.txt"
fi
# need to figure out a way to continue to add to the frequencies.txt without duplicating stars that have already been added to the file