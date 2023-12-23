<p align=center>
    <img src="images/repotitle.png">
</p>

-----------

This is a simple image corruptor that utilizes [ImageMagick](https://imagemagick.org/ and [FFmpeg](https://ffmpeg.org/).

# Latest Changelog
- Almost everything rewritten. I already forgot what got added.
- Ability to specify variables through switches
- Custom fiilter

# How 2 use dis? (yep, this is just the help message.)
```
Informational:
 --help		Show this help message
 --license	Self-explanatory
 --debug	Debug info
 
Script Usage:
 -i=<input>
 -o=<output>
 -f=<filter>
 -s=<filter args>
 
Examples:
$ ./corruptor.sh -i=input.png -o=output.png -f=custom -s="acrusher=bits=16:samples=64"

$ ./corruptor.sh -i=input.png -o=output.png -f=lowpass -s=7000
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
- ~~Ability to specify variables through switches~~ *Done!*
- ~~MORE FILTERS!~~ *Proper custom filter implemented!*
- SoX filters?
- Different raw image formats?
