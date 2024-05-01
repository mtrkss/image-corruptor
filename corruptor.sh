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
hsize=54

if [ "$(uname -o)" = Android ] || [ "$(uname -o)" = Toybox ]
then tmpdir=./tmp
else tmpdir=/tmp/imgcorrupt
fi

# help & licensing
case "$*" in
	"" | *-"hel"*) cat <<EOF

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
 lavfi   - Only use if you know what you\`re doing. Use with -c
 debug   - Don\`t delete temporary files, print out all the set variables and halt the script midway for inspection.

EOF
exit ;;
  *"licens"*) sed -n '2,15{s/^#//;p}' $0; exit ;;
esac

# set some variables

switches() {
local args="$*"

# loop through each arg
for arg in $args; do
  case $arg in
    -i=*) input="${arg#*=}" ;;
    -o=*) output="${arg#*=}" ;;
    -f=*) filter="${arg#*=}" ;;
    -a=*) format="${arg#*=}" ;;
    -r=*) rate="${arg#*=}" ;;
    -d=*) depth="${arg#*=}" ;;
    -c=*) complex="${arg#*=}" ;;
    -s=*) src="${arg#*=}" ;;
    --debug) debug=y ;;
    --lavfi) lavfi=y ;;
    --alpha) alpha=y ;;
   --limit) limit=y ;;
    *) ;;  # ignore any other args
  esac
done
}
switches "$*"

# functions
varset() {
hash=$(shasum "$1"|head -c10)
ucimg=${tmpdir}/ucimg-$hash.bmp
cimg=${tmpdir}/cimg-$hash.bmp
inter=${tmpdir}/inter-$hash.raw
}

error() {
printf 'Error: %s\n' "$*"
exit 1
}

getfile() {
file="$1"
if [ ! -f "$file" ]; then
  error "Input file doesn't exist, is a folder, or a special device." 66
elif ! file -b "$file" | grep -qE 'image|bitmap|pixmap'; then
  error "Input file is not an image." 66
fi
varset "$file"
}

debug() {
cat <<EOF
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
complex> $complex
lavfi>   $lavfi
rate>    $rate
limit>   $limit

Press enter...
EOF
read nothing
}

chkapp() {
if which $1 2>/dev/null
then printf "$1 found\n\n"
else error "$1 not found! Please install the $2 package."
fi
}

ffwrong() {
printf "FFmpeg exited with a non-0 code!\nContinue? (may be risky) [y/N]: "
read ans
echo $ans | grep -qi y || exit 1
}

chkapp ffmpeg ffmpeg
chkapp convert ImageMagick

[ -d "$tmpdir" ] || mkdir "$tmpdir" || error "Can't create a temporary directory!"
[ -f "$src" ] && printf "%s\n" "Using $3 to source variables" && . "$3"

if [ -z "$input" ]
then error "I need an input image!"
else getfile "$input"
fi

if [ -z "$output" ]
then
output="${hash}.png"
printf "Output not specified! Defaulting to $(pwd)/${output}\n"
fi

if [ -z "$filter" ]
then error "Please add an ffmpeg audio filter as the -f= option." "Docs: https://ffmpeg.org/ffmpeg-filters.html" "Example: -f=acrusher=bits=16:samples=64:mix=0.2"
elif [ -z "$complex" ]
then ffargs="-y -f $format -ar $rate -i $ucimg -af $filter -f $format $inter"
else ffargs="-y -f $format -ar $rate -i $ucimg $([ -z $lavfi ]||printf %s-f\ lavfi) -i $complex -filter_complex $filter -f $format $inter"
fi

# corruption
[ ! -z $debug ] && printf "Everything correct here?\n" && debug
convert "$input" -depth $depth -alpha $([ -z $alpha ] && printf %soff || printf %son) $ucimg

echo ffmpeg $ffargs || ffwrong
ffmpeg $ffargs || ffwrong

# restoring the header
head -c$hsize $ucimg > $cimg
if [ -z $limit ]
then tail -c$(($(wc -c<$inter) - $hsize)) $inter >> $cimg
else tail -c+$(($hsize + 1)) $inter | head -c$(($(wc -c<$ucimg) - $hsize)) >> $cimg 
fi

# convert the resulting image
convert $cimg "$output"

# cleanup & debug info
if [ ! -z $debug ]
then debug
else
	printf "Cleaning up...\n"
	rm -rv "$tmpdir" && printf "Done\n\n"
fi
