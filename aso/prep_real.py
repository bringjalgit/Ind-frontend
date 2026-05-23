import os
from PIL import Image
import numpy as np

SRC = '../../..'  # d:/Indbackend  (aso is .../indiclassifiedsNew/indiclassifiedsNew/aso)
def src(name):
    return os.path.join(SRC, 'WhatsApp Image 2026-05-22 at %s.jpeg' % name)

# 1) home + listings: copy as-is into shots/
Image.open(src('9.49.44 PM (2)')).convert('RGB').save('shots/home_full.jpg', quality=92)
Image.open(src('9.49.44 PM (1)')).convert('RGB').save('shots/listings_full.jpg', quality=92)

# 2) splash: detect the grey status band at top and crop it off
im = Image.open(src('9.49.43 PM')).convert('RGB')
arr = np.asarray(im).astype(np.int16)
# grey band rows are darker/less warm than the cream splash. Find first row that
# looks "cream" (bright + warm) for a sustained stretch.
def is_cream(row):
    r, g, b = row[:, 0].mean(), row[:, 1].mean(), row[:, 2].mean()
    return r > 225 and g > 222 and b > 210 and (r - b) >= 4  # bright, slightly warm
cut = 0
for y in range(0, 160):
    if is_cream(arr[y]):
        cut = y
        break
print('splash status band ends at y =', cut, ' (of', im.size[1], ')')
im.crop((0, cut, im.size[0], im.size[1])).save('shots/splash_clean.jpg', quality=92)
print('saved home_full, listings_full, splash_clean (cropped %dpx)' % cut)
