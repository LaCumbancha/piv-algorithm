# Imports

import numpy as np
import utils.images as utils
import piv.interface as interface

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


# Mocking inputs

scale = 1
time_delta = 1
window_size = 32
input_images = utils.load_images()
points = {1: Point(400, 800, input_images)}

# Running PIV

start = datetime.now()
frontend_input = InputPIV(points, time_delta, scale, window_size)
output_data = interface.calculate_piv(frontend_input)
end = datetime.now()

# Results

print(f'X: {output_data[1].x}')
print(f'Y: {output_data[1].y}')
print(f'U: {output_data[1].u}')
print(f'V: {output_data[1].v}')
print(f'S2N: {output_data[1].s2n}')
print(f'Computation time: {str(end - start)}')
