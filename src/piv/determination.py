# Imports

import numpy as np
import scipy.ndimage

from piv.model import OutputPIV


## Vector field determination
# Here it's where magic happens, calculating peaks and doing science stuff to get the proper PIV data.
#
# Output: OutputPIV object

S2N_FILTER = False
DEFAULT_S2N_THRESHOLD = 1
DEFAULT_RES_NORMALIZATION = 255
def vector_field_determination(correlation, int_window, step, min_x, max_x, min_y, max_y):
	
	# Normalize result
	squeezed_min_corr = correlation.min(0).min(0).squeeze()[:, np.newaxis, np.newaxis]
	squeezed_delta_corr = correlation.max(0).max(0).squeeze()[:, np.newaxis, np.newaxis] - squeezed_min_corr
	min_res = np.tile(squeezed_min_corr, [1, correlation.shape[0], correlation.shape[1]]).transpose([1, 2, 0])
	delta_res = np.tile(squeezed_delta_corr, [1, correlation.shape[0], correlation.shape[1]]).transpose([1, 2, 0])
	corr = ((correlation - min_res) / delta_res) * DEFAULT_RES_NORMALIZATION
	
	# Find peaks and S2N
	x1, y1, indexes1, x2, y2, indexes2, s2n = find_all_displacements(corr)
	
	# Sub-pixel determination
	pixel_offset = 1 if (int_window % 2 == 0) else 0.5
	vector = sub_pixel_gaussian(corr, int_window, x1, y1, indexes1, pixel_offset)
	
	# Create data
	x_range = np.arange(min_x, max_x + 1, step)
	y_range = np.arange(min_y, max_y + 1, step)
	output_x = np.tile(x_range + int_window / 2, [len(y_range), 1])
	output_y = np.tile(y_range[:, None] + int_window / 2, [1, len(x_range)])
	vector = np.reshape(vector, np.append(np.array(output_x.transpose().shape), 2), order='F').transpose([1, 0, 2])

	# Signal to noise filter
	s2n = s2n[np.reshape(np.array(range(output_x.size)), output_x.transpose().shape, order='F').transpose()]
	if S2N_FILTER:
		vector[:,:,0] = vector[:,:,0] * (s2n > DEFAULT_S2N_THRESHOLD)
		vector[:,:,1] = vector[:,:,1] * (s2n > DEFAULT_S2N_THRESHOLD)
	
	output_u = vector[:,:,0]
	output_v = vector[:,:,1]

	output_x -= int_window/2
	output_y -= int_window/2

	return OutputPIV(output_x, output_y, output_u, output_v, s2n)
	
	
## Gaussian sub-pixel mode
# No f*cking clue what this does. Crazy math shit.
#
# Output: A vector with a sub-pixel deviation - Maybe? I'm not sure. Its dimensions are Number-of-Correlations by 2. 

def sub_pixel_gaussian(correlation, int_window, x, y, indexes, pixel_offset):
	z = np.array(range(indexes.shape[0])).transpose()
	
	xi = np.nonzero(np.logical_not(np.logical_and(
		# Adjusting -1 to -2 according to Matlab/Python mapping.
		np.logical_and(x <= correlation.shape[1] - 2, y <= correlation.shape[0] - 2),
		np.logical_and(x >= 2, y >= 2)
	)))[0]

	x = np.delete(x, xi)
	y = np.delete(y, xi)
	z = np.delete(z, xi)
	x_max = correlation.shape[1]
	vector = np.ones((correlation.shape[2], 2)) * np.nan

	if len(x) > 0:
		ip = np.ravel_multi_index(np.array([x, y, z]), correlation.shape, order='F')
		flattened_correlation = correlation.flatten(order='F')

		f0 = np.log(flattened_correlation[ip])
		f1 = np.log(flattened_correlation[ip - 1])
		f2 = np.log(flattened_correlation[ip + 1])
		peak_y = y + (f1 - f2) / (2 * f1 - 4 * f0 + 2 * f2)

		f1 = np.log(flattened_correlation[ip - x_max])
		f2 = np.log(flattened_correlation[ip + x_max])
		peak_x = y + (f1 - f2) / (2 * f1 - 4 * f0 + 2 * f2)
	
		sub_pixel_x = peak_x - (int_window / 2) - pixel_offset
		sub_pixel_y = peak_y - (int_window / 2) - pixel_offset
	
		vector[z, :] = np.array([sub_pixel_x, sub_pixel_y]).transpose()
	
	return vector

	
## Find all displacements
# Find all integer pixel displacement in a stack of correlation windows.
#
# Output: Horizontal and vertical indexes of the first and second maximum for each slice of correlation in the third
# dimension (PeakX1, PeackY1, PeakX2, PeakY2), the absolute indexes of the correlation maximums (Idx1, Idx2) and the
# ratio between the first and second peack (S2N) - 0 indicates non confiable results.

def find_all_displacements(correlation):
	corr_size = correlation.shape[0]
	
	# Finding first peak
	peak1_val, peak1_x, peak1_y, peak_indexes1, peak_positions1 = find_peaks(correlation)

	# Finding second peak (1 extra point from Matlab size)
	filter_size = 10 if corr_size >= 64 else 5 if corr_size >= 32 else 4
	filtered = scipy.ndimage.correlate(peak_positions1, np.ones([filter_size, filter_size, 1]), mode='constant')
	correlation = (1 - filtered) * correlation
	peak2_val, peak2_x, peak2_y, peak_indexes2, _ = find_peaks(correlation)

	# Calculating Signal to Noise ratio
	signal_to_noise = np.zeros([peak1_val.shape[0]])
	signal_to_noise[peak2_val != 0] = peak1_val[peak2_val != 0] / peak2_val[peak2_val != 0]

	# Maximum at a border usually indicates that MAX took the first one it found, so we should put a bad S2N, like 0.
	signal_to_noise[peak1_y == 0] = 0
	signal_to_noise[peak1_x == 0] = 0
	signal_to_noise[peak1_y == (corr_size - 1)] = 0
	signal_to_noise[peak1_x == (corr_size - 1)] = 0
	signal_to_noise[peak2_y == 0] = 0
	signal_to_noise[peak2_x == 0] = 0
	signal_to_noise[peak2_y == (corr_size - 1)] = 0
	signal_to_noise[peak2_x == (corr_size - 1)] = 0
	
	return peak1_x, peak1_y, peak_indexes2, peak2_x, peak2_y, peak_indexes2, signal_to_noise
	
	
## Find peaks
# Find max values for each correlation.
#
# Output: The MAX peak, its coordinates (X and Y) and the indexes.
	
def find_peaks(correlation):
	corr_size = correlation.shape[0]
	corr_numbers = correlation.shape[2]
	max_peak = correlation.max(0).max(0)
	max_positions = correlation == np.tile(max_peak[np.newaxis, np.newaxis, ...], [corr_size, corr_size, 1])
	max_indexes = np.where(max_positions.transpose(2, 1, 0).flatten())[0]
	peak_y, peak_x, peak_z = np.unravel_index(max_indexes, (corr_size, corr_size, corr_numbers), order='F')

	# If two elements equals to the max we should check if they are in the same layer and take the first one.
	# Surely the second one will be the second highest peak. Anyway this would be a bad vector.
	unique_max_indexes = np.unique(peak_z)
	max_indexes = max_indexes[unique_max_indexes]
	peak_x = peak_x[unique_max_indexes]
	peak_y = peak_y[unique_max_indexes]
	
	return max_peak, peak_x, peak_y, max_indexes, max_positions
