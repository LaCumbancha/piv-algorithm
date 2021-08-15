from setuptools import setup

# File created following instructions:
# 1. JetBrains: https://www.jetbrains.com/help/pycharm/creating-and-running-setup-py.html
# 2. Python: https://packaging.python.org/guides/distributing-packages-using-setuptools/#setup-args

setup(
    name='piv-algorithm',
    version='0.2.0',
    packages=['piv', 'piv.core', 'piv.model', 'piv.framed', 'piv.phases', 'piv.filters', 'piv.interface',
              'piv.correlation', 'piv.preparation', 'piv.determination', 'utils'],
    url='https://github.com/LaCumbancha/piv-algorithm',
    license='License',
    author='Cristian Raña',
    author_email='cerana@fi.uba.ar',
    description='PIV aglorithm',
    python_requires='>=3',
    install_requires=['numpy', 'scipy', 'oct2py']
)
