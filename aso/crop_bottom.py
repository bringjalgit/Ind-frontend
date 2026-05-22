from PIL import Image
import numpy as np

def crop_black_bottom(path):
    im = Image.open(path).convert('RGB')
    arr = np.asarray(im).astype(int)
    bright = arr.mean(axis=2)            # HxW brightness
    dark_frac = (bright < 45).mean(axis=1)  # per-row fraction of dark pixels
    y = im.height - 1
    while y > 0 and dark_frac[y] > 0.6:  # row dominated by black = gesture bar
        y -= 1
    cropped = im.height - 1 - y
    im.crop((0, 0, im.width, y + 1)).save(path, quality=92)
    print('%s: cropped %d px of black bottom -> %s' % (path, cropped, (im.width, y + 1)))

for p in ['shots/home_nb.jpg', 'shots/listings_nb.jpg', 'shots/splash_clean.jpg']:
    crop_black_bottom(p)
