from PIL import Image
import os
os.makedirs('cardimg', exist_ok=True)
im = Image.open('shots/browse_light.jpg').convert('RGB')  # 717x1600

cols = {1: 100, 2: 272, 3: 444, 4: 616}
catrows = {1: (998, 1082), 2: (1160, 1248), 3: (1322, 1410)}
HALF = 72
categories = {
    'phone': (1, 1), 'bike': (2, 1), 'car': (3, 1), 'building': (4, 1),
    'coworking': (1, 2), 'education': (2, 2), 'fridge': (3, 2), 'chair': (4, 2),
    'jobs': (1, 3), 'lifestyle': (2, 3), 'dog': (3, 3), 'services': (4, 3),
}
for name, (c, r) in categories.items():
    cx = cols[c]; y0, y1 = catrows[r]
    im.crop((cx - HALF, y0, cx + HALF, y1)).save('cardimg/%s.png' % name)

# What's New rectangular thumbs (band just above the Categories heading)
WN = (770, 848); HALFW = 80
for name, c in {'community': 1, 'investor': 2, 'films': 3, 'events': 4}.items():
    cx = cols[c]
    im.crop((cx - HALFW, WN[0], cx + HALFW, WN[1])).save('cardimg/wn_%s.png' % name)

# Home promo banner
im.crop((14, 286, 703, 560)).save('cardimg/banner.png')

# montage of the newly added category tiles + whatsnew to verify alignment
check = ['coworking', 'education', 'jobs', 'lifestyle', 'services',
         'wn_community', 'wn_investor', 'wn_films', 'wn_events']
th = [Image.open('cardimg/%s.png' % n) for n in check]
w = max(t.width for t in th); h = max(t.height for t in th)
M = Image.new('RGB', (w * len(th), h), (34, 34, 34))
for i, t in enumerate(th):
    M.paste(t, (i * w, 0))
M.save('cardimg/_montage2.png')
print('done. categories+whatsnew+banner cropped. montage', M.size)
