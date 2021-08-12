# Imports

import math
import utils.list

import numpy as np
import numpy.matlib as npmb


## Prepare images for PIV
# Determine which indices must be used to create the interrogation windows. 
# It also add a padding dark color to the images.
#
# Output: Indexes for vectors (MinX, MaxX, MinY, MaxY), the padded images and the interrogation window indexes.

def prepare_piv_images(images, window_size, step):
    
    # Calculating vectors.
    min_x = 1 + math.ceil(step)
    min_y = 1 + math.ceil(step)
    size_y, size_x = utils.list.first(images)[0].shape
    max_x = step * math.floor(size_x / step) - (window_size - 1) + math.ceil(step)
    max_y = step * math.floor(size_y / step) - (window_size - 1) + math.ceil(step)
    vectors_u = math.floor((max_x - min_x)/step + 1)
    vectors_v = math.floor((max_y - min_y)/step + 1)
    
    # Centering image grid.
    pad_x = size_x - max_x
    pad_y = size_y - max_y
    shift_x = max(0, round((pad_x - min_x) / 2))
    shift_y = max(0, round((pad_y - min_y) / 2))
    min_x += shift_x
    min_y += shift_y
    max_x += shift_x
    max_y += shift_y
    
    # Adding a dark padded border to images.
    padded_images = []
    for idx in range(len(images)):
        padded_images += [[]]
        for frame in range(2):
            image = images[idx][frame]
            padded_images[idx] += [np.pad(image, math.ceil(window_size-step), constant_values=image.min())]
        padded_images[idx] = np.array(padded_images[idx])
    padded_images = np.array(padded_images)
    
    # Interrogation window indexes for first frame.
    padded_size_y, padded_size_x = utils.list.first(padded_images)[0].shape
    min_s0 = npmb.repmat(np.array(np.arange(min_y, max_y + 1, step) - 1)[:, None], 1, vectors_u)
    max_s0 = npmb.repmat(np.array(np.arange(min_x, max_x + 1, step) - 1) * padded_size_y, vectors_v, 1)
    s0 = np.asarray(min_s0 + max_s0).flatten()[..., np.newaxis, np.newaxis].transpose([1, 2, 0])

    min_s1 = npmb.repmat(np.array(np.arange(1, window_size + 1))[:, None], 1, window_size)
    max_s1 = npmb.repmat(np.array(np.arange(1, window_size + 1) - 1) * padded_size_y, window_size, 1)
    s1 = min_s1 + max_s1

    indexes = np.tile(np.asarray(s1)[..., np.newaxis], [1, 1, s0.shape[2]]) + np.tile(s0, [window_size, window_size, 1]) - 1
    
    return min_x, max_x, min_y, max_y, padded_images, indexes
