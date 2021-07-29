## Reading images
# Loading images as an IxJ matrix, containing the intensity of each pixel.
#
# Output: 
# Array with the following dimensions: 0 - Image; 1 - Height (Y); 2 - Width (X).

from PIL import Image

def load_images():
    images = []
    
    for IMAGE in [IMAGE_1, IMAGE_2]:
        imag = Image.open(IMAGE)
        grayscale_image = imag.convert("L")
        grayscale_array = np.asarray(grayscale_image)
        images += [np.array(grayscale_array)]
    
    return np.array(images)

def load_fake_images(x=100, y=None, total_images=5, mode='const'):
    if not y:
        y = x
    count = 1
    images = []
    for idx in range(total_images):
        if mode == 'rand':
            images += [(np.random.rand(x, y) * 100).astype(np.uint8)]
        elif mode == 'inc':
            images += [np.reshape(np.arange(count, count + x * y), [x, y], order='F')]
            count += x * y
        else:
            images += [np.ones((x, y), np.uint8) * (idx + 1)]
    return np.array(images)
