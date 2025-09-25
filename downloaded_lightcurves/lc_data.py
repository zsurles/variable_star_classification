# create a script that takes the lightcurve data from files with ####.csv (NOT _ztf.csv) and gets the average amount of data points (brightness measurements, basically the number of rows) and the average time that the data was taken over (so final jd - first jd) and gets the average over ALL of these files
# only account for files that have g-band data
# potentially only use the .txt files

# IMPORTS
import os
import re
import pandas as pd
from tqdm import tqdm

data_dir = "/Users/zoesurles/Desktop/variable_star_classification/downloaded_lightcurves"

total_points = 0
total_time = 0  # in years
file_count = 0

digit_txt_pattern = re.compile(r"^\d+\.txt$")
files = [f for f in os.listdir(data_dir) if digit_txt_pattern.match(f)]

for file in tqdm(files, desc="Processing files"):
    path = os.path.join(data_dir, file)
    try:
        # No header row → assign a column name
        df = pd.read_csv(path, delim_whitespace=True, header=None, usecols=[0])
        df.columns = ["jd"]
    except Exception as e:
        print(f"⚠️ Skipping {file} (read error: {e})")
        continue

    if len(df) < 2:  # need at least 2 points
        print(f"⚠️ Skipping {file} (not enough rows)")
        continue
    
    df = df.sort_values("jd")
    
    if len(df) < 2:  # need at least 2 points
        print(f"⚠️ Skipping {file} (not enough rows)")
        continue
    
    num_points = len(df)
    time_span = (df["jd"].iloc[-1] - df["jd"].iloc[0]) / 365.25  # JD → years
    
    total_points += num_points
    total_time += time_span
    file_count += 1

# Compute averages
average_points = total_points / file_count if file_count > 0 else 0
average_time = total_time / file_count if file_count > 0 else 0  # in years

# Convert average time into years + months
years = int(average_time)
months = int(round((average_time - years) * 12))

print(f"\nProcessed {file_count} valid files")
print(f"Average number of data points: {average_points:.2f}")
print(f"Average time span: {years} years {months} months (≈ {average_time:.2f} years)")
