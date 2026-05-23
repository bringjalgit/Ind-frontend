from PIL import Image
# strip the real status bar (~56px) off home + listings so we can render the
# clean 9:41 / 5G status bar in HTML instead (matching the mockup screens)
for name in ['home_full', 'listings_full']:
    im = Image.open('shots/%s.jpg' % name).convert('RGB')
    im.crop((0, 56, im.size[0], im.size[1])).save('shots/%s_nb.jpg' % name.replace('_full', ''),
                                                   quality=92)
    print('cropped', name, '->', name.replace('_full', '') + '_nb.jpg')
