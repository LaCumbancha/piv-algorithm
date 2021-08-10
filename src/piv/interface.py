# Imports

import numpy as np
import piv.core as core
import piv.framed as framed


## Communication Input data model
# An ad-hoc object with the images to analyze and the algorithm settings. 
# Points: Dictionary with the Point ID as key and a ad-hoc object with PositionX, PositionY and a list of the two images (as PIL.Image.Image) as value.
# Settings.TimeDelta: Time between two images, iin miliseconds.
# Settings.Scale: Image scaling, in pixels per milimeters.
# Settings.WindowSize: Interrogation window size, default is 32.

class InputPIV:
    def __init__(self, points, time_delta, scale, window_size):
        self.points = points
        self.settings = Settings(time_delta, scale, window_size)
        

class Settings:
    def __init__(self, time_delta, scale, window_size):
        self.time_delta = time_delta
        self.scale = scale
        self.window_size = window_size
        

class Point:
    def __init__(self, pos_x, pos_y, images):
        self.pos_x = pos_x
        self.pos_y = pos_y
        self.images = images
        
        
## Communication Exceptions
# Exception thrown when some parameters weren't passed as expected.
        
class InvalidParametersError(Exception):
    pass


## Retrieve point
# Get the point positions in the desired format.
#
# Output: the point as (Y-Position, X-Position).

def retrieve_point_position(point_id, markers):
    if point_id not in markers:
        raise InvalidParametersError(f'Markers for point {point_id} missing.')
        
    point = markers[point_id]
    return (point.pos_y, point.pos_x)


## ROI indexes
# Calculate the ROI indexes with the ROI size, the image size and the defined point
#
# Output: the ROI as an array, with format [X-start X-end Y-start Y-end], for example: [1 100 1 50].

def roi_indexes(point, image_shape, roi_size=None):
    if not roi_size:
        return []
    
    max_y, max_x = image_shape
    point_y, point_x = point
    middle_roi = int(roi_size / 2)
    
    start_x = max(0, point_x - middle_roi)
    start_y = max(0, point_y - middle_roi)
    end_x = min(max_x - 1, point_x + middle_roi)
    end_y = min(max_y - 1, point_y + middle_roi)
    
    return [start_x, end_x, start_y, end_y]


## Entrypoint (WIP)
# Retrieve the images, prepare them and calculate the PIV computation.
#
# Output: OutputPIV object

DEFAULT_INTERROGATION_WINDOW = 32
def calculate_piv(frontend_data):
    results = {}
    settings = frontend_data.settings
    
    # TODO: Check if this could be parallelized to increase performance.
    for point_id, input_images in frontend_data.images.items():
        
        # TODO: Check if the images should be transformed first (like, to a grey scale).
        point_position = retrieve_point_position(point_id, settings.markers)
        roi = roi_indexes(point_position, input_images[0].shape, settings.roi_size)

        double_framed_images = framed.single_to_double_frame(input_images, roi=roi)
        if double_framed_images.size <= 2:
            raise InvalidParametersError(f'Not enough images passed for point {point_id}')
        
        piv_data = core.PIV(double_framed_images, settings.int_window)
        piv_data.x = piv_data.x * settings.scale
        piv_data.y = piv_data.y * settings.scale
        piv_data.u = piv_data.u * settings.scale / settings.time_delta
        piv_data.v = piv_data.v * settings.scale / settings.time_delta
        
        results[point_id] = piv_data
    
    return results
