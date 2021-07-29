## Filter fields
# Applies different filters on the vector fields.
#
# WIP!
#
# Output: OutputPIV object, with filtered data

import numpy as np

DEFAULT_B = 1
DEFAULT_THRESH = 1.5
DEFAULT_EPSILON = 0.02
DEFAULT_STD_THRESHOLD = 4
def filter_fields(data, std_threashold=DEFAULT_STD_THRESHOLD):
    # Filter 1: Threshold on signal to noise.  
    data.u = remove_nans(data.u)
    data.v = remove_nans(data.v)
    
    # Filter 2:
    mean_u = np.mean(data.u)
    mean_v = np.mean(data.v)
    std_u = np.std(data.u, ddof=1)
    std_v = np.std(data.v, ddof=1)
    min_u = mean_u - std_threashold * std_u
    max_u = mean_u + std_threashold * std_u
    min_v = mean_v - std_threashold * std_v
    max_v = mean_v + std_threashold * std_u
    data.u[data.u < min_u] = np.nan
    data.u[data.u > max_u] = np.nan
    data.v[data.v < min_v] = np.nan
    data.v[data.v > max_v] = np.nan
    
    # Filter 3:
    
    
## Remove NANs
# Replace all the NANs from a data vector with a custom interpolation calculated with its values.
#
# Output: 

DEFAULT_PATCH_SIZE = 1
def remove_nans(data, patch_size=DEFAULT_PATCH_SIZE):
    nan_indexes = np.where(np.isnan(data))[0]
    fixed_data = data.copy()

    if nan_indexes.size > 0:
        data_size = data.shape[0]

        for nan_idx in nan_indexes:
            sample = data[max(0, nan_idx - patch_size):min(data_size, nan_idx + patch_size + 1)]
            sample = sample[~np.isnan(sample)]
        
            new_data = np.median(sample) if sample.size > 0 else 0
            # Possible bug in the original code. If new_data is 0 for a certain index, it clears the previous ones.
            
            fixed_data[nan_idx] = new_data
            
    return fixed_data
