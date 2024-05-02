<p align=center>
    <img src="images/repotitle.png">
</p>

-----------

This is a simple image corruptor that utilizes [ImageMagick](https://imagemagick.org/) and [FFmpeg](https://ffmpeg.org/).

# Latest Changelog

- Removed "-s="
- Cleaned up the script
- Fixed a possible bug with the image header size

# How 2 use dis?

1. Install FFmpeg and ImageMagick with your package manager
2. Run the script with `sh corruptor.sh` on Android or `./corruptor.sh` on other platforms.

(you may need to `chmod +x corruptor.sh` first before running)

<details>
	<summary>Built-in help message</summary>

```
"image-corruptor.sh" is a simple POSIX Shell script for adding glitch effects to images e.g. corrupting them.
The corruption process utilizes ImageMagick, FFmpeg and Coreutils.

Options:

 VAR     SWITCH    FUNCTION
 input   (-i=)     - Input file
 output  (-o=)     - Output file
 filter  (-f=)     - FFmpeg audio filter
 complex (-c=)     - Complex FFmpeg audio input
 depth   (-d=)     - Image depth
 format  (-a=)     - Intermediate audio format
 rate    (-r=)     - Intermediate audio rate
 src     (-s=)     - File with predefined variables
 debug   (--debug) - Enable simple debug info
 lavfi   (--lavfi) - Presume lavfi -au format
 alpha   (--alpha) - Enable image alpha channel
 limit   (--limit) - Limit processed bytes to input image size (raw)

Info:

 complex - Second FFmpeg input
 filter  - See https://ffmpeg.org/ffmpeg-filters.html
 format  - See "ffmpeg -formats"
 limit   - Use a different algorhithm for restoring file headers, limiting the raw output filesize to the raw input filesize.
 alpha   - Enable the alpha channel.
 lavfi   - Only use if you know what you're doing. Use with -c
 debug   - Don't delete temporary files, print out all the set variables and halt the script midway for inspection.
```
</details>

The simplest way to corrupt an image with this script would be `./corruptor.sh -i=input.png -f=lowpass`

If no output file is specified, the name will be generated automatically.

# Tested OSes
- Arch Linux
- Void Linux
- Fedora Linux
- NixOS
- FreeBSD
- Android
- MacOS (only Apple Silicon tested)

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
- More testing, some features break the output images.
- Fix mtrkss/video-corruptor
