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

def PIV(images, int_window, overlap=DEFAULT_OVERLAP):
    step = round(int_window * overlap / 100)
    min_x, max_x, min_y, max_y, padded_images, indexes = prepare_piv_images(images, int_window, step)
    correlation = cumulative_cross_correlation(padded_images, indexes, int_window)
    raw_piv_data = vector_field_determination(correlation, int_window, step, min_x, max_x, min_y, max_y)
    filtered_piv_data = filter_fields(data)
    return filtered_piv_data
