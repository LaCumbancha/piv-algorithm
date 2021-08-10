## Imports

import numpy as np
from PIL import Image


## Reading images
# Loading images as an IxJ matrix, containing the intensity of each pixel.
#
# Output: 
# Array with the following dimensions: 0 - Image; 1 - Height (Y); 2 - Width (X).

IMAGE_1 = './images/Image 1a.png'
IMAGE_2 = './images/Image 1b.png'

def load_images(images_paths=[IMAGE_1, IMAGE_2]):
	images = []
	
	for image in images_paths:
		img = Image.open(image)
		grayscale_image = img.convert("L")
		grayscale_array = np.asarray(grayscale_image)
		images += [np.array(grayscale_array)]
	
	return np.array(images)


def load_fake_images(y=100, x=None, total_images=5, mode='const'):
	if not x:
		x = y
	count = 1
	images = []
	for idx in range(total_images):
		if mode == 'rand':
			images += [(np.random.rand(y, x) * 100).astype(np.uint8)]
		elif mode == 'inc':
			images += [np.reshape(np.arange(count, count + y * x), [y, x], order='F')]
			count += y * x
		else:
			images += [np.ones((y, x), np.uint8) * (idx + 1)]
	return np.array(images)
