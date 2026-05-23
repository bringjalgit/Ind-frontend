import os
import numpy as np
from PIL import Image

SRC = '../../..'
def src(name):
    return os.path.join(SRC, 'WhatsApp Image 2026-05-22 at %s.jpeg' % name)

def bottom_black(im):
    arr = np.asarray(im.convert('RGB')).astype(int)
    df = (arr.mean(axis=2) < 45).mean(axis=1)
    y = im.height - 1
    while y > 0 and df[y] > 0.6:
        y -= 1
    return y + 1

# Register (grey status band) — detect first bright row = end of grey band
im = Image.open(src('11.37.53 PM')).convert('RGB')
bright = np.asarray(im).astype(int).mean(axis=(1, 2))
top = 0
while top < 220 and bright[top] < 225:
    top += 1
bot = bottom_black(im)
im.crop((0, top, im.width, bot)).save('shots/register_real.jpg', quality=92)
print('register_real: top=%d bot=%d -> %s' % (top, bot, (im.width, bot - top)))

# What-are-you-posting (white status bar) — fixed top crop
im2 = Image.open(src('11.38.34 PM')).convert('RGB')
top2 = 80
bot2 = bottom_black(im2)
im2.crop((0, top2, im2.width, bot2)).save('shots/whatposting.jpg', quality=92)
print('whatposting: top=%d bot=%d -> %s' % (top2, bot2, (im2.width, bot2 - top2)))
