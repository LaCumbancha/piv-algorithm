## Imports

import piv.interface as interface
import utils.images as images

from datetime import datetime
from piv.interface import InputPIV, Marker


## Mocking inputs

SCALE = 1
ROI_SIZE = 300
ROI_SIZE = None
TIME_DELTA = 1
INTERROGATION_WINDOW = 32

input_images = images.load_images()
images = { 1: input_images, 2: input_images }
markers = { 1: Marker(100, 200), 2: Marker(780, 560) }


## Running PIV

start = datetime.now()
frontend_input = InputPIV(images, TIME_DELTA, SCALE, INTERROGATION_WINDOW, ROI_SIZE, markers)
output_data = interface.calculate_piv(frontend_input)
end = datetime.now()

print(f'Computation time: {str(end - start)}')