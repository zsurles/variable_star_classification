for i in *_classification.txt; do 
    if grep -q 'class = RR' "$i"; then                                                     
        asassn_id=$(basename "$i" _classification.txt)
        if ! grep -q "asassn_id = $asassn_id" RRconfirmed.txt; then
            cat "$i" >> RRconfirmed.txt
        fi
    fi
done

