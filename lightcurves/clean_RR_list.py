import pandas as pd
import numpy as np
from tqdm import tqdm   # <-- new import

# Constants
R_J = 0.91  # From Yuan et al. 2013
R_K = 0.39

# ---- Progress bar setup ----
steps = [
    "Load data",
    "Basic preprocessing",
    "Error propagation",
    "RR selection",
    "CMD filtering",
    "Save results"
]
pbar = tqdm(total=len(steps), desc="Processing stars")

# --- 1. Load raw data ---
data = pd.read_csv("distance_color_type_for_all_stars_csv.csv")
pbar.update(1)

# --- 2. Basic preprocessing ---
data["FinalType"] = data["FinalType"].astype(str).str.rstrip(":")
data["J-K"] = data["J_mag"] - data["K_mag"]
data = data[data["J-K"] > -1]
pbar.update(1)

# --- 3. Error propagation ---
data["J-K_err"] = np.sqrt(data["J_mag_err"]**2 + data["K_mag_err"]**2)
data["sigma_distance"] = (data["distance_high"] - data["distance_low"]) / 2
data["sigma_dist_term"] = (5/np.log(10)) * (data["sigma_distance"] / data["distance"])

data["E(B-V)"] = data["ext_correct_J"] / R_J
data["A_J"] = R_J * data["E(B-V)"]
data["E(J-K)"] = (R_J - R_K) * data["E(B-V)"]

data["abs_mag_J"] = data["J_mag"] - 5 * np.log10(data["distance"]) + 5 - data["A_J"]

data["abs_mag_J_err"] = np.sqrt(
    data["J_mag_err"]**2 +
    data["sigma_dist_term"]**2 +
    (0.1 * data["A_J"])**2  # conservative extinction error
)
pbar.update(1)

# --- 4. Select RR types only ---
rr_types = ["RRAB", "RRC", "RR(B)"]
rr_data = data[data["FinalType"].isin(rr_types)].copy()
pbar.update(1)

# --- 5. Define RR Lyrae regions ---
jk_region = (
    (rr_data["J-K"] > 0.05) & (rr_data["J-K"] < 0.60) &
    (rr_data["abs_mag_J"] > -1.2) & (rr_data["abs_mag_J"] < 0.85)
)
gaia_region = rr_data["abs_mag_G"] < (1.5 * rr_data["BP_RP_0"] + 0.75)

# --- 6. Apply both CMD masks ---
final_clean_rr = rr_data[jk_region & gaia_region].copy()
pbar.update(1)

print("Total stars in raw data:", len(data))
print("RR candidates (before CMD filtering):", len(rr_data))
print("Final clean RR Lyrae count:", len(final_clean_rr))

# --- 7. Save result ---
final_clean_rr.to_csv("final_clean_rr_list.csv", index=False)
pbar.update(1)
pbar.close()
