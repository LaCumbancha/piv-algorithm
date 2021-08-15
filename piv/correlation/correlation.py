# Imports

import numpy as np

from octave import octave_cli


# Cumulative cross correlation (WIP)
# Averages correlation maps from an image stack.
#
# Output: A correlation matrix with the same size as the images input.

NORMALIZED_CORRELATION_RESOLUTION = 2**8
def cumulative_cross_correlation(images, indexes, window_size):
    
    total_correlation = 0
    for idx, frames in enumerate(images):
        frame_a = frames[0].flatten(order='F').take(indexes).astype(np.single)
        frame_b = frames[1].flatten(order='F').take(indexes).astype(np.single)

        # Calculating cross correlation
        correlation = octave_cli.correlate(frame_a, frame_b, window_size)
        
        # Normalizing correlation
        min_corr = np.tile(correlation.min(0).min(0), [correlation.shape[0], correlation.shape[1], 1])
        max_corr = np.tile(correlation.max(0).max(0), [correlation.shape[0], correlation.shape[1], 1])
        norm_corr = (correlation - min_corr) / (max_corr - min_corr) * (NORMALIZED_CORRELATION_RESOLUTION - 1)
    
        total_correlation += norm_corr/len(images)
        
    return total_correlation
