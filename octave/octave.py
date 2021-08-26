# Imports
import os

from oct2py import Oct2Py

temp_folder = "/tmp/piv"
os.makedirs(temp_folder, exist_ok=True)
octave_cli = Oct2Py(temp_dir=temp_folder)
octave_cli.addpath('./matlab/')
