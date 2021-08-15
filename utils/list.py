# Imports

import numpy as np


# Utils

def first(a_list):
    return a_list[0]


def last(a_list):
    return a_list[-1]


def group_by(a_list, a_func=lambda x: x):
    output_dict = {}

    for a_elem in a_list:
        key = a_func(a_elem)
        if key in output_dict:
            output_dict[key] = np.append(output_dict[key], a_elem[None, :], axis=0)
        else:
            output_dict[key] = np.array([a_elem])

    return list(output_dict.values())
