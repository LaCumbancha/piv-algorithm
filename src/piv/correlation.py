# Imports

import numpy as np


## Cumulative cross correlation
# Averages correlation maps from an image stack.
#
# TODO: This function isn't working properly! Matlab FFT ≠ Numpy FFT.
# Should fix the cross correlation calculation and also check the normalization (different shape expected).
#
# Output: A correlation matrix with the same size as the images input.

NORMALIZED_CORRELATION_RESOLUTION = 2**8
def cumulative_cross_correlation(images, indexes, window_size):
    
    total_correlation = 0
    for idx, image in enumerate(images):
        frame_a = image[0].take(indexes).astype(np.single)
        frame_b = image[1].take(indexes).astype(np.single)
        
        # Calculating cross correlation
        fft_a = np.fft.fft2(frame_a)
        fft_b = np.fft.fft2(frame_b)

        fft_shifting = np.real(np.fft.ifft(np.fft.ifft(np.conj(fft_a) * fft_b, window_size, 1), window_size, 0))
        correlation = np.fft.fftshift(np.fft.fftshift(fft_shifting, 2), 1)
        correlation[correlation < 0] = 0
        
        # Normalizing correlation
        min_corr = np.tile(correlation.min(0).min(0), [correlation.shape[0], correlation.shape[1], 1])
        max_corr = np.tile(correlation.max(0).max(0), [correlation.shape[0], correlation.shape[1], 1])
        norm_corr = (correlation - min_corr) / (max_corr - min_corr) * (NORMALIZED_CORRELATION_RESOLUTION - 1)
    
        total_correlation += norm_corr/len(images)
        
    return total_correlation
