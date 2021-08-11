## Communication Input data model
# An ad-hoc object with the images to analyze, the points and the algorithm settings. 
# Points: Dictionary with the Point ID as key and a ad-hoc object with PositionX, PositionY and a list of the two images (as PIL.Image.Image) as value.
# Settings.TimeDelta: Time between two images, iin miliseconds.
# Settings.Scale: Image scaling, in pixels per milimeters.
# Settings.WindowSize: Interrogation Window size, default is 32.
# Settings.RoiSize: Region of Interest size, default is None which will be used as the full image.

class InputPIV:
	def __init__(self, points, time_delta, scale, window_size=32, roi_size=None):
		self.points = points
		self.settings = Settings(time_delta, scale, window_size, roi_size)
		

class Settings:
	def __init__(self, time_delta, scale, window_size, roi_size):
		self.time_delta = time_delta
		self.scale = scale
		self.window_size = window_size
		self.roi_size = roi_size
		

class Point:
	def __init__(self, pos_x, pos_y, images):
		self.pos_x = pos_x
		self.pos_y = pos_y
		self.images = images


## Communication Output data model
# An ad-hoc object with the following fields: X, Y, U (X velocity), V (Y velocity) and S2N (signal to noise ratio).

class OutputPIV:
	def __init__(self, x, y, u, v, s2n):
		self.x = x
		self.y = y
		self.u = u
		self.v = v
		self.s2n = s2n
