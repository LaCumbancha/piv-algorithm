# Imports

from oct2py import Oct2Py

octave_cli = Oct2Py()
octave_cli.addpath('./matlab/')
octave_cli.eval('pkg load image')
