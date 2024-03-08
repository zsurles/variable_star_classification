# imports
import pandas as pd
import numpy as np
from astropy.io import ascii
from astropy.table import QTable, Table, Column
from astropy import units as u
import upsilon


# Read in the data and make a table
column1 = []
column2 = []
column3 = []
column4 = []
with open('rrlyr_vsx_clean.txt', 'r') as file:
    for line in file:
        empty = []
        components = line.split(' ', 3)
    
        column1.append(components[0])
        column2.append(float(components[1]))
        column3.append(float(components[2]))
        column4.append(components[3].strip())
final_table = QTable([column1, column2, column3, column4], names = ("Star Type", "RA", "Dec", "Other Info"))


# Download lightcurves
from pyasassn.client import SkyPatrolClient	
client = SkyPatrolClient()

search = client.cone_search(ra_deg = final_table["RA"][3], dec_deg = final_table["Dec"][3], radius=0.0003, catalog='master_list', download=True)
print(search)

path = search.save(save_dir='/Users/zoesurles/Desktop/variable_star_classification/downloaded_lightcurves/', file_format="csv")[1]


new_file = pd.read_csv(path, skiprows=1)
g_filter = new_file[new_file['phot_filter'] == 'g']
web_format = g_filter[["jd", "mag", "mag_err"]]
web_format.to_csv('/Users/zoesurles/Desktop/variable_star_classification/downloaded_lightcurves/output.txt', sep='\t', index=False, header = False)