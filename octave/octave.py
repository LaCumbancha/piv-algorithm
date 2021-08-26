# Imports
import os

from oct2py import Oct2Py

# tmp dir needs to be specified, else it'll break
# https://stackoverflow.com/a/63406242
temp_folder = os.path.join(os.getcwd(), "tmp")
os.makedirs(temp_folder, exist_ok=True)
octave_cli = Oct2Py(temp_dir=temp_folder)
octave_cli.addpath('./matlab/')
