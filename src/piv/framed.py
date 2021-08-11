# Imports

import utils.list
import numpy as np


## Single to double frame
# Combines images by 2, returning an array with two frames (one for each image). 
#
#   Input: 5 images with step 1.
#   Output: 4 double-framed images.
#      FrameA:  1  2  3  4
#      FrameB:  2  3  4  5
#
#   Input: 8 images with step 3.
#   Output: 5 doubled-framed images.
#      FrameA:  1  2  3  4  5
#      FrameB:  4  5  6  7  8
#
# This function also crops the image according to the provided Region of Interest (ROI), that must be passed as:
# ROI = [X-start X-end Y-start Y-end], for example: [1 100 1 50].
#
# Output:
# Array with the following dimensions: 0 - Image; 1 - Frame; 2 - Height (Y); 3 - Width (X).

def single_to_double_frame(images, step=1, roi=None):
	total_images = images.shape[0]

	frameA_idx = list(range(0,total_images-step))
	frameB_idx = [idx+1 for idx in frameA_idx]

	height, width = utils.list.first(images).shape
	mask = np.ones([height, width], np.uint8)

	images_double_framed = []
	for idx in frameA_idx:
		double_frame = [images[frameA_idx[idx]], images[frameB_idx[idx]]]
			
		if roi and len(roi) == 4:
			size_y, size_x = double_frame[0].shape
			min_x, max_x = max(0, roi[0]-1), min(roi[1], size_x)
			min_y, max_y = max(0, roi[2]-1), min(roi[3], size_x)
			
			double_frame[0] = np.array(double_frame[0][min_y:max_y, min_x:max_x])
			double_frame[1] = np.array(double_frame[1][min_y:max_y, min_x:max_x])

		images_double_framed += [double_frame]
			
	return np.array(images_double_framed)
