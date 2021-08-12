# Caudalímetro de Microfluídos

El presente proyecto cuenta como TP2 de la materia (75.61) Taller de Programación III de la FIUBA, en colaboración con el Laboratorio de Fluidodinámica de la facultad que requieren de dicha herramienta para posteriores investigaciones.

## Abstract

La medición de caudal en microfluídica es difícil debido a los muy bajos caudales utilizados. Una de las técnicas utilizadas para ello es la microvelocimetría por imágenes de partículas. Esta técnica consiste en "sembrar" en el flujo partículas fluorescentes que son observadas en dos imágenes consecutivas, con un delta de tiempo conocido entre ellas. Luego de una correlación entre las imágenes se obtiene el desplazamiento en píxeles de un conjunto de partículas. Procesar toda la imagen permite obtener un "campo de velocidades", pero esto podría llevar mucho tiempo de procesamiento. La idea de este trabajo es solo procesar una parte de la imagen (por ejemplo fragmentos de 64x64 pixels), y obtener la velocidad de dicho probe en tiempo real.

## Requiremets

* Python 3+

### Libraries

Here are listed the libraries needed to run the project, with the installation scripts for MacOS.

* Numpy

```bash
pip install numpy
```

* Scipy

```bash
pip install scipy
```

