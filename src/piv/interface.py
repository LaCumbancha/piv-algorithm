# Imports

import numpy as np
import piv.core as core
import piv.framed as framed

from piv.model import OutputPIV
		
		
## Communication Exceptions
# Exception thrown when some parameters weren't passed as expected.
		
class InvalidParametersError(Exception):
	pass


## Prepare output
# Get the velocity for the desired point. If it is not possible, it will get it for the closest point.
#
# Output: OutputPIV object

def prepare_output(center_x, center_y, piv_data):
	idx_x = (np.abs(piv_data.x[:,1] - center_x)).argmin()
	idx_y = (np.abs(piv_data.y[1,:] - center_y)).argmin()

	position_x = int(piv_data.x[idx_x,1]) + 1
	position_y = int(piv_data.y[1,idx_y]) + 1
	velocity_x = piv_data.u[idx_x,idx_y]
	velocity_y = piv_data.v[idx_x,idx_y]
	signal_to_noise = piv_data.s2n[idx_x,idx_y]
	
	return OutputPIV(position_x, position_y, velocity_x, velocity_y, signal_to_noise)


## Entrypoint
# Retrieve the images, prepare them and calculate the PIV computation.
#
# Output: OutputPIV object

DEFAULT_INTERROGATION_WINDOW = 32
def calculate_piv(frontend_data):
	results = {}
	settings = frontend_data.settings
	
	# TODO: Check if this could be parallelized to increase performance.
	for point_id, point_data in frontend_data.points.items():

		double_framed_images = framed.single_to_double_frame(point_data.images)
		if double_framed_images.size <= 2:
			raise InvalidParametersError(f'Not enough images passed for point {point_id}')
			
		shift_x = 0
		shift_y = 0
		if settings.roi_size is not None:
			roi_shift = int(settings.roi_size / 2)
			shift_x = point_data.pos_x - roi_shift
			shift_y = point_data.pos_y - roi_shift
		
		piv_data = core.PIV(double_framed_images, settings.window_size)
		piv_data.x = piv_data.x * settings.scale + shift_x
		piv_data.y = piv_data.y * settings.scale + shift_y
		piv_data.u = piv_data.u * settings.scale / settings.time_delta
		piv_data.v = piv_data.v * settings.scale / settings.time_delta
		
		point_results = prepare_output(point_data.pos_x - 1, point_data.pos_y - 1, piv_data)
		results[point_id] = point_results
	
	return results
