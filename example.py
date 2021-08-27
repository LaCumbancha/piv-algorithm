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


if __name__ == "__main__":

    # Mocking inputs

    IMAGE_1 = './extras/images/Image 5a.png'
    IMAGE_2 = './extras/images/Image 5b.png'
    images_paths = [IMAGE_1, IMAGE_2]

    scale = 1
    time_delta = 1
    window_size = 16
    input_images = utils.load_images(images_paths)

    point_1 = Point(452, 127, input_images)
    point_2 = Point(440, 180, input_images)
    point_3 = Point(500, 300, input_images)
    points = {1: point_1, 2: point_2, 3: point_3}

    # Running PIV

    start = datetime.now()
    frontend_input = InputPIV(points, time_delta, scale, window_size, roi_size=512)
    output_data = piv.calculate_piv(frontend_input)
    end = datetime.now()

    # Results

    for point_id, point_piv in output_data.items():
        print(f'POINT {point_id}:')
        print(f'--------')
        print_output(point_piv)
        print()

    print(f'Computation time: {str(end - start)}')
