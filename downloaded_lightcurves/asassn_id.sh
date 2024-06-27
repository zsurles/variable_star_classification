for i in *_classification.txt; do 
    if grep -q 'class = RR' "$i"; then                                                     
        asassn_id=$(basename "$i" _classification.txt)
        if ! grep -q "asassn_id = $asassn_id" RRconfirmed.txt; then
            echo "$asassn_id" >> asassn_id_only.txt
        fi
    fi
done

# need to figure out a way to continue to add to the asassn_id_only.txt without duplicating stars that have already been added to the file
