<p align=center>
    <img src="images/repotitle.png">
</p>

-----------

This is a simple image corruptor that utilizes [ImageMagick](https://imagemagick.org/) and [FFmpeg](https://ffmpeg.org/).

# Latest Changelog
<details>
	<summary>TOO. MUCH.</summary>

- Merged video-corruptor features
- Added adjustable image bitdepth
- Added adjustable ffmpeg corruption arate
- Added optional alpha channel
- Added a second image restoration technique used with --limit
- Added another input file
- Added complex filters
- Added lavfi filters
- Better debug message
- Added complete Android (termux) support
- 
- Now using a separate directory in /tmp for temporary files
</details>

# How 2 use dis?

1. Install FFmpeg and ImageMagick with your package manager
2. Run the script with `sh corruptor.sh` on Android or `./corruptor.sh` on other platforms.

(you may need to `chmod +x corruptor.sh` first before running)

<details>
	<summary>Built-in help message</summary>

```
Files:
 -i=<input>
 -o=<output>
 -au=<complex audio input>
 
Corruption:
 -f=<filter>
 -s=<filter args>
 -d=<intermediate image bit depth>
 -a=<intermediate audio format>
 -r=<intermediate audio frequency>

Other:
 --help		Show this help message
 --license	Self-explanatory
 --debug	Debug info, don't delete temp files
 --lavfi	Presume lavfi -au format
 --alpha	Enable image alpha channel
 --limit	Limit the amount of processed raw output bytes (helps with conversion errors)

Examples:
$ ./corruptor.sh -i=input.png -o=output.png -f=lowpass -s=7000
$ ./corruptor.sh -i=input.png -o=output.png -f=custom -s="acrusher=bits=16:samples=64:mix=0.2,lowpass=f=7000,volume=-2dB"
```
</details>

The simplest way to corrupt an image with this script would be `./corruptor.sh -i=input.png -f=lowpass`

If no output file is specified, the name will be generated automatically.

# Tested platforms
- Arch Linux
- Void Linux
- Fedora Linux
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
- Remove lowpass and highpass. There are too many ffmpeg filters to implement as -f=*.
- More testing, some features break the output images.
