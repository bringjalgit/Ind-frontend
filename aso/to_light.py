"""
Convert dark-theme app screenshots to a light-theme look by inverting
LIGHTNESS while preserving hue & saturation (HSL L' = 1 - L).

- black bg -> white, white text -> black
- saturated accents (blue buttons, etc.) keep their hue
- NOTE: photographs get luminance-inverted (look unnatural) — this is only
  suitable for chrome-heavy screens with few/no real photos.

Usage: python to_light.py
Outputs to shots_light/.
"""
import os
import numpy as np
from PIL import Image

SRC = os.path.join(os.path.dirname(__file__), 'shots')
OUT = os.path.join(os.path.dirname(__file__), 'shots_light')
os.makedirs(OUT, exist_ok=True)

EPS = 1e-12

def rgb_to_hsl(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = rgb.max(axis=-1)
    mn = rgb.min(axis=-1)
    l = (mx + mn) / 2.0
    d = mx - mn
    nz = d > EPS
    s = np.where(l < 0.5, d / (mx + mn + EPS), d / (2.0 - mx - mn + EPS))
    s = np.where(nz, s, 0.0)
    h = np.zeros_like(l)
    rmax = nz & (mx == r)
    gmax = nz & (mx == g) & ~rmax
    bmax = nz & (mx == b) & ~rmax & ~gmax
    h = np.where(rmax, ((g - b) / (d + EPS)) % 6.0, h)
    h = np.where(gmax, ((b - r) / (d + EPS)) + 2.0, h)
    h = np.where(bmax, ((r - g) / (d + EPS)) + 4.0, h)
    h = (h / 6.0) % 1.0
    return h, s, l

def _hue2rgb(p, q, t):
    t = t % 1.0
    return np.where(t < 1/6, p + (q - p) * 6 * t,
           np.where(t < 1/2, q,
           np.where(t < 2/3, p + (q - p) * (2/3 - t) * 6, p)))

def hsl_to_rgb(h, s, l):
    q = np.where(l < 0.5, l * (1 + s), l + s - l * s)
    p = 2 * l - q
    r = _hue2rgb(p, q, h + 1/3)
    g = _hue2rgb(p, q, h)
    b = _hue2rgb(p, q, h - 1/3)
    gray = s < EPS
    r = np.where(gray, l, r); g = np.where(gray, l, g); b = np.where(gray, l, b)
    return np.stack([r, g, b], axis=-1)

def convert(name):
    img = Image.open(os.path.join(SRC, name)).convert('RGB')
    arr = np.asarray(img).astype(np.float64) / 255.0
    h, s, l = rgb_to_hsl(arr)
    out = hsl_to_rgb(h, s, 1.0 - l)
    out = np.clip(out * 255, 0, 255).astype(np.uint8)
    Image.fromarray(out).save(os.path.join(OUT, name), quality=95)
    print('light ->', name)

if __name__ == '__main__':
    for f in sorted(os.listdir(SRC)):
        if f.lower().endswith(('.jpg', '.jpeg', '.png')) and f != 'splash.jpg':
            convert(f)
    print('done. see', OUT)
