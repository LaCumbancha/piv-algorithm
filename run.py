# Imports

import piv
import numpy as np
import utils.images as utils

from datetime import datetime
from piv.model import InputPIV, Point


# Test utils

def crop_images(images, center=None, size=None):
    if center is None or size is None:
        return images

    cropped_images = []
    center_x, center_y = center
    padding = int((size - 1) / 2)

    for image in images:
        cropped_images += [
            image[(center_y - padding):(center_y + padding + 1), (center_x - padding):(center_x + padding + 1)]]

    return np.asarray(cropped_images)


def print_output(point_piv):
    print(f'X: {point_piv.x}')
    print(f'Y: {point_piv.y}')
    print(f'U: {point_piv.u}')
    print(f'V: {point_piv.v}')
    print(f'S2N: {point_piv.s2n}')


# Mocking inputs

IMAGE_1 = './extras/images/Image 1a.png'
IMAGE_2 = './extras/images/Image 1b.png'
images_paths = [IMAGE_1, IMAGE_2]

scale = 1
time_delta = 1
window_size = 32
input_images = utils.load_images(images_paths)

point_1 = Point(815, 548, input_images)
point_2 = Point(692, 512, input_images)
points = { 1: point_1, 2: point_2 }

# Running PIV

start = datetime.now()
frontend_input = InputPIV(points, time_delta, scale, window_size)
output_data = piv.calculate_piv(frontend_input)
end = datetime.now()

# Results

output_point_1 = output_data[1]
output_point_2 = output_data[2]


print(f'POINT 1:')
print(f'--------')
print_output(output_point_1)

print(f'POINT 2:')
print(f'--------')
print_output(output_point_2)

print(f'Computation time: {str(end - start)}')
