Drop your captured app screenshots here.

Required filenames (match the SLIDES list in ../screenshots.html):
  swa.png        -> Sell with AI screen (chat with AI pills / offer flow)
  auth.png       -> New login / sign-in screen
  browse.png     -> Home / browse listings
  dashboard.png  -> SWA seller dashboard (tabs)
  chat.png       -> Buyer chat screen
  boost.png      -> Plans / boost screen

Capture tips
------------
- Use the 1.3.1 build on a phone or emulator with CLEAN, real-looking data
  (no "test test", no placeholder junk) — these are marketing shots.
- Portrait, 1080 wide is ideal (1080x1920 or 1080x2400 both work; the frame
  crops from the top, so keep the important content near the top).
- Hide the status bar clutter if you can (enable demo mode), or it's fine to
  leave a clean status bar.

Capture from a connected device (adb):
  adb exec-out screencap -p > swa.png

Then open ../screenshots.html via a local server (see the note in that file)
and click "Download all PNGs".
