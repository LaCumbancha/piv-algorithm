## Imports

import piv.filters as filters
import piv.correlation as correlation
import piv.preparation as preparation
import piv.determination as determination


## PIV Output data model
# An ad-hoc object with the following fields: X, Y, U (X velocity), V (Y velocity) and S2N (signal to noise ratio).

class OutputPIV:
    def __init__(self, x, y, u, v, s2n):
        self.x = x
        self.y = y
        self.u = u
        self.v = v
        self.s2n = s2n
    

## Calculate PIV
# Generate the PIV data from the images loaded with the input parameters.
#
# Output: OutputPIV object

DEFAULT_OVERLAP = 50
def PIV(images, int_window, overlap=DEFAULT_OVERLAP):
    step = round(int_window * overlap / 100)
    min_x, max_x, min_y, max_y, padded_images, indexes = preparation.prepare_piv_images(images, int_window, step)
    cross_correlation = correlation.cumulative_cross_correlation(padded_images, indexes, int_window)
    raw_piv_data = determination.vector_field_determination(cross_correlation, int_window, step, min_x, max_x, min_y, max_y)
    filtered_piv_data = filters.filter_fields(data)

    data.x = data.x.transpose()
    data.y = data.y.transpose()
    data.u = data.u.transpose()
    data.v = data.v.transpose()
    data.s2n = data.s2n.transpose()
    
    return filtered_piv_data
