from PIL import Image, ImageDraw
im = Image.open('shots/browse_light.jpg').convert('RGB')  # 717x1600
strip = im.crop((359, 850, 529, 1260)).copy()  # column 3 strip, y 850..1260
d = ImageDraw.Draw(strip)
for yy in range(0, strip.height, 20):
    d.line([(0, yy), (strip.width, yy)], fill=(255, 0, 0), width=1)
    d.text((2, yy + 1), str(850 + yy), fill=(255, 0, 0))
strip.save('cardimg/_strip3.png')
print('strip3', strip.size)
