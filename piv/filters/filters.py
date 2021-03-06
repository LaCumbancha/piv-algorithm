# Imports

import numpy as np
import scipy.sparse
import scipy.ndimage
import scipy.sparse.linalg

from octave import octave_cli


# Filter fields (WIP)
# Applies different filters on the vector fields.
#
# Output: OutputPIV object, with filtered data.

B = 1
EPSILON = 0.02
DEFAULT_THRESH = 1.5
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
    size_y, size_x = data.u.shape
    normal_fluctuation = np.zeros(shape=(size_y, size_x, 2))

    for it in range(2):
        velocity_comparator = data.u if it == 0 else data.v
        neighbors = np.empty(shape=(size_y - 2, size_x - 2, 2 * B + 1, 2 * B + 1))

        for ii in range(-B, B + 1):
            for jj in range(-B, B + 1):
                ii_start = 1 + B - 1 + ii
                ii_end = -B + ii if -B + ii < 0 else None
                jj_start = 1 + B - 1 + jj
                jj_end = -B + jj if -B + jj < 0 else None

                ii_neighbors = ii + 2 * B - 1
                jj_neighbors = jj + 2 * B - 1

                neighbors[:, :, ii_neighbors, jj_neighbors] = velocity_comparator[ii_start:ii_end, jj_start:jj_end]

        first_neighbors = np.arange((2 * B + 1) * B + B)
        last_neighbors = np.arange((2 * B + 1) * B + B + 1, (2 * B + 1) ** 2)
        neighbors_column = np.reshape(neighbors, [neighbors.shape[0], neighbors.shape[1], (2 * B + 1) ** 2], order='F')
        neighbors_column2 = neighbors_column[:, :, np.append(first_neighbors, last_neighbors)].transpose([2, 0, 1])

        median = np.median(neighbors_column2, axis=0).transpose()
        velocity_comparator2 = velocity_comparator[B:-B, B:-B]
        fluctuation = velocity_comparator2 - median.transpose()
        result = neighbors_column2 - np.tile(median, [(2 * B + 1) ** 2 - 1, 1, 1]).transpose([0, 2, 1])

        median_result = np.median(np.abs(result), axis=0)
        normal_fluctuation[B:-B, B:-B, it] = np.abs(fluctuation / (median_result + EPSILON))

    info = np.sqrt(normal_fluctuation[:, :, 0] ** 2 + normal_fluctuation[:, :, 1] ** 2) > DEFAULT_THRESH
    data.u[info] = np.nan
    data.v[info] = np.nan
    
    # Inpaint NANs
    data.u = inpaint_nans(data.u)
    data.v = inpaint_nans(data.v)
    
    # Filter 4:
    try:
        
        # Trying to apply the smooth predictor.
        data.u = smooth(data.u)
        data.v = smooth(data.v)
        
    except:
        
        # Applying Gaussian filter instead.
        gfilter = gaussian_filter(5, 1)
        data.u = scipy.ndimage.convolve(data.u, gfilter, mode='nearest')
        data.v = scipy.ndimage.convolve(data.v, gfilter, mode='nearest')
    
    return data
    

# Remove NANs
# Replace all the NANs from a data vector with a custom interpolation calculated with its values.
#
# Output: A matrix with the same dimensions ang items as the input, but with NANs replaced.

DEFAULT_PATCH_SIZE = 1
def remove_nans(data, patch_size=DEFAULT_PATCH_SIZE):
    both_nan_indexes = list(zip(*np.where(np.isnan(data))))
    size_y, size_x = data.shape

    fixed_data = data.copy()
    for y_idx, x_idx in both_nan_indexes:
        sample = data[
            max(0, y_idx - patch_size):min(size_y, y_idx + patch_size + 1), 
            max(0, x_idx - patch_size):min(size_x, x_idx + patch_size + 1)
        ]

        sample = sample[~np.isnan(sample)]
        new_data = np.median(sample) if sample.size > 0 else 0

        fixed_data[y_idx, x_idx] = new_data

    return fixed_data


# Inpaint NANs
# Solves approximation to one of several pdes to interpolate and extrapolate holes in an array.
# It uses a spring metaphor, assuming they (with a nominal length of zero) connect each node with every neighbor 
# (horizontally, vertically and diagonally). Since each node tries to be like its neighbors, extrapolation is as a 
# constant function where this is consistent with the neighboring nodes.
#
# Output: A matrix with the same dimensions ang items as the input, but with NANs replaced.

DEFAULT_SPRING_ITERATIONS = 4
def inpaint_nans(data, iterations=DEFAULT_SPRING_ITERATIONS):
    size_y, size_x = data.shape
    flattened = data.flatten(order='F')

    # List the nodes which are known, and which will be interpolated.
    nan_indexes = np.where(np.isnan(flattened))[0]
    known_indexes = np.where(~np.isnan(flattened))[0]

    # Get total NANs overall.
    nan_count = nan_indexes.size

    # Convert NAN indexes to [Row, Column] form.
    indexes_y, indexes_x = np.unravel_index(nan_indexes, (size_y, size_x), order='F')

    # All forms of index in one array: 0 - Unrolled ; 1 - Row ; 2 - Column
    nan_list = np.array([nan_indexes, indexes_y, indexes_x]).transpose() + 1

    # Spring analogy - interpolating operator.
    # List of all springs between a node and a horizontal or vertical neighbor.
    hv_list = np.array([[-1, -1, 0], [1, 1, 0], [-size_y, 0, -1], [size_y, 0, 1]])
    hv_springs = np.empty((0, 2))

    for it in range(iterations):
        hvs = nan_list + np.tile(hv_list[it, :], (nan_count, 1))
        k = np.logical_and(
            np.logical_and(hvs[:, 1] >= 1, hvs[:, 1] <= size_y),
            np.logical_and(hvs[:, 2] >= 1, hvs[:, 2] <= size_x)
        )
        hv_springs = np.append(hv_springs, np.array([nan_list[k, 0], hvs[k, 0]]).transpose(), axis=0)
    
    # Delete replicate springs    
    hv_springs.sort(axis=1)
    hv_springs = np.unique(hv_springs, axis=0) - 1

    # Build sparse matrix of connections.
    # Springs connecting diagonal neighbors are weaker than the horizontal and vertical ones.
    nhv = hv_springs.shape[0]
    I, V = np.tile(np.arange(0, nhv)[:, None], (1, 2)).flatten(), np.tile([1, -1], (nhv, 1)).flatten()
    springs = scipy.sparse.csr_matrix((V, (I, hv_springs.flatten())), shape=(nhv, data.size))
    springs.eliminate_zeros()

    # Eliminate knowns
    rhs = springs[:, known_indexes] * flattened[known_indexes] * -1

    # Solve problem
    output = flattened
    solution, _, _, _, _, _, _, _, _, _ = scipy.sparse.linalg.lsqr(springs[:, nan_indexes], rhs)
    output[nan_indexes] = solution

    return np.reshape(output, (size_x, size_y)).transpose()


# Smooth predictor
# Fast, automatized and robust discrete spline smoothing for data of arbitrary dimension.
# Automatically smooths the uniformly-sampled input array. It can be any N-D noisy array (time series, images,
# 3D data, ...). Non finite data (NaN or Inf) are treated as missing values.
#
# Output: A matrix with the same dimensions ang items as the input, but with NANs replaced.

def smooth(data):
    return octave_cli.smoothn(data)

    
# Gaussian filter
# Returns a Gaussian filter with the same implementation as Matlab.
#
# Output: A matrix that works as a Gaussian filter.

def gaussian_filter(size=3, sigma=0.5):
    m, n = [(ss-1.)/2. for ss in (size, size)]
    y, x = np.ogrid[-m:m+1, -n:n+1]
    h = np.exp(-(x*x + y*y) / (2.*sigma*sigma))
    h[h < np.finfo(h.dtype).eps * h.max()] = 0
    sumh = h.sum()
    if sumh != 0:
        h /= sumh
    return h
