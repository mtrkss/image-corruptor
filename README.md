<p align=center>
    <img src="images/repotitle.png">
</p>

-----------

This is a simple image corruptor that utilizes [ImageMagick](https://imagemagick.org/ and [FFmpeg](https://ffmpeg.org/).

# Latest Changelog
- More filters
- Fixed a bug with image drifts

# How 2 use dis?
```
./corruptor.sh help # help
./corruptor.sh license # licensing
./corruptor.sh image <filter> # normal usage 
./corruptor.sh image <filter> debug # additional debug info
```

# Known Bugs
Probably many since this script has only been tested on FreeBSD.

# Corrupted Images
`custom "acrusher=bits=16:samples=12"`
<p>
    <img src="images/i1.png">
</p>

`custom "acrusher=bits=16:samples=200:mix=0.1"`
<p>
    <img src="images/i2.png">
</p>

# TODO
- Ability to specify variables and output file through switches
- MORE FILTERS!
- SoX filters?
- Different raw image formats?
