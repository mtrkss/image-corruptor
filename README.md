<p align=center>
    <img src="images/repotitle.png>
</p>
-----------
This is a simple image corruptor that utilizes [ImageMagick](https://imagemagick.org/) and [FFmpeg](https://ffmpeg.org/).

# How 2 use dis?
```
./corruptor.sh help # help
./corruptor.sh license # licensing
./corruptor.sh image *filter* # normal usage 
./corruptor.sh image *filter* debug # debug info
```

# Known Bugs
Probably many because this script has only been tested on FreeBSD, but the only one I know about is image drifting.
Every time you corrupt an image, a little piece from the right side gets moved to the left one the whole image shifts. This shouldn't happen in theory, but it does.

# Corrupted Images
<p>
    <img src="images/i1.png>
</p>
<p>
    <img src="images/i2.png>
</p>
