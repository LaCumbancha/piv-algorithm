# Imports

import utils
import numpy as np


# Filter fix
# Scipy's filters are displaced by +1 at both axis. so this function will fix that difference.
#
# Output: The same filter but with that Scipy vs Matlab difference fixed.

def fix_filter(full_filter):
    indexes_y, indexes_x, indexes_z = np.where(full_filter)
    indexes = np.array(list(zip(indexes_y, indexes_x, indexes_z)))
    grouped = np.array(utils.group_by(indexes, lambda index: index[2]))

    new_indexes_raw = np.array(list(map(fix_indexes, grouped)))
    new_indexes = new_indexes_raw[0]
    for new_index in new_indexes_raw[1:]:
        new_indexes = np.append(new_indexes, new_index, axis=0)

    new_indexes_y, new_indexes_x, new_indexes_z = np.split(new_indexes, 3, axis=1)
    new_full_filter = np.zeros(full_filter.shape)
    new_full_filter[new_indexes_y, new_indexes_x, new_indexes_z] = True

    return new_full_filter.astype(dtype=bool)


# Fix indexes
# Subtract one in each index (if it's possible).
#
# Output: The fixed indexes.

def fix_indexes(indexes):
    if indexes[:, 0].min() > 0:
        indexes[:, 0] -= 1
    if indexes[:, 1].min() > 0:
        indexes[:, 1] -= 1
    return indexes
