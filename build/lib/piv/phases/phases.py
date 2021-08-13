# Imports

import numpy as np


# Calculate phases
# Number of phases to reconstruct. If set to 1, no phase reconstruction is achieved.
#
# Output:
# A plain number representing the different phases and and a vector of phases.

def calculate_phases(images, cumulcross=True, acq_freq=1, act_freq=1, default_phases=1):
    if cumulcross:
        T_acquired = np.array(range(len(images))) / acq_freq
        
        if act_freq == 0:
            phases = T_acquired * 0 + 1
            total_phases = 1
        else:
            phases = np.floor(np.mod(T_acquired + 1 / (2 * act_freq), 1 / act_freq) * act_freq * default_phases) + 1
            total_phases = default_phases
    else:
        phases = np.array(range(len(images)))
        total_phases = len(phases)
        
    return total_phases, phases
