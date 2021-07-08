## Imports

import matplotlib.pyploy as plt
import matplotlib.image as mpimg
import numpy as np


## Setting parameters

IMAGE_1 = './images/Image 1a.png'
IMAGE_2 = './images/Image 1b.png'
INTERROGATION_WINDOW = '32x32'
FRAMES_PER_IMAGE = 1


## Main body

img1 = mpimg.imread(IMAGE_1)
img2 = mpimg.imread(IMAGE_2)