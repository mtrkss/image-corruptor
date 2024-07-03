#!/bin/sh
#
# Copyright (c) 2023, 2024 Alexey Laurentsyeu, All rights reserved.
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

unset input output filter imgfmt format rate complex debug lavfi alpha depth limit

format=alaw
rate=44100
depth=8
hsize=138
head=head
tail=tail

# help & licensing
case "$*" in
	"" | *-"hel"*) cat <<EOF>&2

"image-corruptor" is a simple POSIX Shell script for adding glitch effects to images (corrupting them).
The corruption process utilizes ImageMagick, FFmpeg and Coreutils.

Options:

 VAR     SWITCH    FUNCTION
 input   (-i=)     - Input file
 output  (-o=)     - Output file
 filter  (-f=)     - FFmpeg audio filter (see ffmpeg.org/ffmpeg-filters.html)
 complex (-c=)     - Complex FFmpeg audio input
 format  (-a=)     - Intermediate audio format (see "ffmpeg -formats")
 rate    (-r=)     - Intermediate audio rate
 imargs  (-m=)     - Additional ImageMagick arguments
 src     (-s=)     - File with predefined variables
 debug   (--debug) - Enable simple debug info
 lavfi   (--lavfi) - Use lavfi complex input format
 alpha   (--alpha) - Enable alpha channel
 nolim   (--nolim) - Use an older image restoration alghorhithm

To test if everything works you can do
 $ convert -size 300x300 gradient:white-gray -rotate 45 /tmp/some.png
 $ $0 -i=/tmp/some.png -f=earwax,aecho -o=output.png
You should get a corrupted, stripey image from this.

EOF
exit ;;
 	*"licens"*) sed -n 's/#//g;2,15p' $0; exit ;;
esac

for arg in "$@"; do case "$arg" in
	-i=*) input="${arg#*=}" ;;
	-o=*) output="${arg#*=}" ;;
	-f=*) filter="${arg#*=}" ;;
	-a=*) format="${arg#*=}" ;;
	-r=*) rate="${arg#*=}" ;;
	-c=*) complex="${arg#*=}" ;;
	-s=*) src="${arg#*=}" ;;
	-m=*) imargs="${arg#*=}" ;;
	-debug|--debug) debug=y ;;
	-lavfi|--lavfi) lavfi=y ;;
	-alpha|--alpha) alpha=y ;;
	-nolim|--nolim) nolim=y ;;
	*) echo "Argument $arg does not exist!" >&2 ;;
esac; done

# functions
varset() {
hash=$($sum "$1"|awk '{print$1}'|$head -c10)
ucimg=${tmpdir}/ucimg-$hash.bmp
cimg=${tmpdir}/cimg-$hash.bmp
inter=${tmpdir}/inter-$hash.raw
}

error() {
printf 'Error: %s\n' "$*" >&2
exit 1
}

getfile() {
file="$1"
if ! [ -f "$file" ]; then
	error "Input file doesn't exist, is a folder, or a special device."
elif ! file -b "$file" | grep -qE 'image|bitmap|pixmap'; then
	error "Input file is not an image."
fi
varset "$file"
}

debug() {
cat <<EOF>&2
Debug info

Internal variables:
hash>    $hash
ucimg>	 $ucimg
cimg>    $cimg
inter>	 $inter
ffargs>  $ffargs

User input:
input>   $input
output>  $output
filter>  $filter
format>  $format
rate>    $rate
complex> $complex
imargs>   $imarg

alpha>   $alpha
lavfi>   $lavfi
nolim>   $nolim

src>     $src

Press enter...
EOF
read nothing
}

chkapp() {
if ! which $1 2>/dev/null >/dev/null; then
	error "$1 not found! Please install the $2 package."
fi
}

ffwrong() {
printf "FFmpeg exited with a non-0 code!\nContinue? (may be risky) [y/N]: " >&2
read ans
echo $ans | grep -qi y || exit 1
}

chkapp ffmpeg ffmpeg
chkapp magick imagemagick

# rough multiplatform fix
if [ "$(uname -o 2>/dev/null)" = Android ]; then
	tmpdir=./imgcorrupt
	sum=md5sum
elif [ "$(uname)" = OpenBSD ]; then
	chkapp ghead coreutils
	chkapp gtail coreutils
	tmpdir=/tmp/imgcorrupt
	sum="md5 -q"
	head=ghead
	tail=gtail
elif [ "$(uname)" = Linux ]; then # should work for most distros
	tmpdir=/tmp/imgcorrupt
	if which md5sum 2>/dev/null >/dev/null; then
		sum=md5sum
	else
		sum=shasum
	fi
elif [ "$(uname)" = Darwin ]; then
	tmpdir=/tmp/imgcorrupt
	sum=shasum
else # should work for FreeBSD, NetBSD and Haiku.
	tmpdir=./imgcorrupt
	if which md5sum 2>/dev/null >/dev/null; then
		sum=md5sum
	elif which shasum 2>/dev/null >/dev/null; then
		sum=shasum
	elif which md5 2>/dev/null >/dev/null; then
		sum=md5 -q
	else
		printf "Warning! Using cksum for the shasum command.\n"
		sum=cksum
	fi
fi

[ -f "$src" ] && printf "Using $3 to source variables\n" && . "$3"

if [ -z "$input" ]; then
	error "I need an input image!"
else
	getfile "$input"
fi

if [ -z "$output" ]; then
	output="${hash}.png"
	printf "Output not specified! Defaulting to $(pwd)/${output}\n" >&2
fi

if [ -z "$filter" ]; then
	error "Please add an ffmpeg audio filter as the -f= option." "Docs: https://ffmpeg.org/ffmpeg-filters.html" "Example: -f=acrusher=bits=16:samples=64:mix=0.2"
elif [ -z "$complex" ]; then
	ffargs="-y -f $format -ar $rate -i $ucimg -af $filter -f $format $inter"
else
	ffargs="-y -f $format -ar $rate -i $ucimg $([ -z $lavfi ]||printf %s-f\ lavfi) -i $complex -filter_complex $filter -f $format $inter"
fi

# corruption
if ! [ -z $debug ]; then
	printf "Everything correct here?\n" >&2
	debug
fi

if ! [ -d $tmpdir ]; then
	mkdir $tmpdir || error "Can't create a temporary directory!"
fi

magick "$input" $imargs -alpha $([ -z $alpha ] && printf %soff || printf %son) $ucimg

ffmpeg $ffargs || ffwrong

# restoring the image
$head -c$hsize $ucimg > $cimg
if [ -z $nolim ]; then
	$tail -c+$((hsize + 1)) $inter | $head -c$(($(wc -c<$ucimg) - hsize)) >> $cimg 
else
	$tail -c$(($(wc -c<$inter) - hsize)) $inter >> $cimg
fi

# convert the resulting image
magick $cimg $imargs "$output"

# cleanup & debug info
if [ ! -z $debug ]; then
	debug
else
	rm -rv "$tmpdir" >&2
fi
