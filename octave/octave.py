# Imports

import os
from oct2py import Oct2Py

# The octave-tmp directory needs to be specified, to avoid an Octave issue: https://stackoverflow.com/a/63406242
temp_folder = os.path.join(os.getcwd(), ".octave-tmp")
os.makedirs(temp_folder, exist_ok=True)
octave_cli = Oct2Py(temp_dir=temp_folder)
octave_cli.addpath('./matlab/')
