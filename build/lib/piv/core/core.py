# Imports

import piv.filters as filters
import piv.correlation as correlation
import piv.preparation as preparation
import piv.determination as determination


# Calculate PIV
# Generate the PIV data from the images loaded with the input parameters.
#
# Output: OutputPIV object

DEFAULT_OVERLAP = 0.5
def piv(images, int_window, overlap=DEFAULT_OVERLAP):
    step = round(int_window * overlap)
    min_x, max_x, min_y, max_y, padded_images, indexes = preparation.prepare_piv_images(images, int_window, step)
    cross_correlation = correlation.cumulative_cross_correlation(padded_images, indexes, int_window)
    raw_piv_data = determination.vector_field_determination(cross_correlation, int_window, step, min_x, max_x, min_y, max_y)
    filtered_piv_data = filters.filter_fields(raw_piv_data)

    filtered_piv_data.x = filtered_piv_data.x.transpose()
    filtered_piv_data.y = filtered_piv_data.y.transpose()
    filtered_piv_data.u = filtered_piv_data.u.transpose()
    filtered_piv_data.v = filtered_piv_data.v.transpose()
    filtered_piv_data.s2n = filtered_piv_data.s2n.transpose()
    
    return filtered_piv_data
