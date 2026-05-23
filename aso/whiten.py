"""
Whiten a converted (inverted) screenshot whose light areas came out greyish /
lavender. Pushes light tones toward pure white and removes their colour tint,
while leaving mid/dark elements (text, blue buttons, icons) untouched.

Usage: python whiten.py shots/register_light.jpg
"""
import sys, numpy as np
from PIL import Image

EPS = 1e-12
WHITE_POINT = 0.90      # L at/above this -> white (levels stretch)
DESAT_LO, DESAT_HI = 0.70, 0.95  # light pixels in this band get desaturated
DESAT_AMT = 0.88        # how much saturation to strip from light pixels

def rgb_to_hsl(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = rgb.max(-1); mn = rgb.min(-1); l = (mx + mn) / 2; d = mx - mn
    nz = d > EPS
    s = np.where(l < 0.5, d / (mx + mn + EPS), d / (2 - mx - mn + EPS))
    s = np.where(nz, s, 0.0)
    h = np.zeros_like(l)
    rm = nz & (mx == r); gm = nz & (mx == g) & ~rm; bm = nz & (mx == b) & ~rm & ~gm
    h = np.where(rm, ((g - b) / (d + EPS)) % 6, h)
    h = np.where(gm, ((b - r) / (d + EPS)) + 2, h)
    h = np.where(bm, ((r - g) / (d + EPS)) + 4, h)
    return (h / 6) % 1, s, l

def _h2(p, q, t):
    t = t % 1.0
    return np.where(t < 1/6, p + (q - p) * 6 * t,
           np.where(t < 1/2, q,
           np.where(t < 2/3, p + (q - p) * (2/3 - t) * 6, p)))

def hsl_to_rgb(h, s, l):
    q = np.where(l < 0.5, l * (1 + s), l + s - l * s); p = 2 * l - q
    r = _h2(p, q, h + 1/3); g = _h2(p, q, h); b = _h2(p, q, h - 1/3)
    gray = s < EPS
    return np.stack([np.where(gray, l, r), np.where(gray, l, g), np.where(gray, l, b)], -1)

def smoothstep(lo, hi, x):
    t = np.clip((x - lo) / (hi - lo), 0, 1)
    return t * t * (3 - 2 * t)

path = sys.argv[1]
img = Image.open(path).convert('RGB')
arr = np.asarray(img).astype(np.float64) / 255
h, s, l = rgb_to_hsl(arr)
l2 = np.minimum(1.0, l / WHITE_POINT)          # lift highlights to white
s2 = s * (1 - DESAT_AMT * smoothstep(DESAT_LO, DESAT_HI, l))  # de-tint light areas
out = np.clip(hsl_to_rgb(h, s2, l2) * 255, 0, 255).astype(np.uint8)
Image.fromarray(out).save(path, quality=95)
print('whitened ->', path)
