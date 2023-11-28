#!/bin/sh
#
# Copyright (c) 2023 Alexey Laurentsyeu, All rights reserved.
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

# help & licensing
case "$*" in
  "" | ?"-h" | ?"-help"*)
    printf '\nThis simple script utilizes ImageMagick and FFmpeg to corrupt images. Nothing special.\n'
    printf "\nUsage:\n> $0 image.png *filter*\n\n"
    exit 0
    ;;
esac

case "$*" in
  *"license"* | *"copyright"*)
	head -n15 $0 | tail -n14 | sed 's/\#//g'
    exit 0
    ;;
esac

# functions =============>

varset() {
hash=$(sha1sum $1 | head -c10)
ucimg=/tmp/ucimg-"$hash".bmp
cimg=/tmp/cimg-"$hash".bmp
inter=/tmp/inter-"$hash".raw
}

gfn() {
printf 'Resulting file name (without extention): '
read fname
if [ "$fname".png = "$1" ]; then
	printf "Output name matches with the input name. Can't continue.\n"
	exit 73
fi
}

# <============= functions


# checks =======================>

if [ "$2" = "" ]; then
	printf 'Please chose a filter as a second switch.\nAvailable filters: "bandreject", "highpass", "lowpass".\n'
	exit 78
elif ! [ -f $1 ]; then
	printf "Input file doesn't exist, is a folder or a special device.\n"
	exit 66
elif ! file -b "$1" | grep -qE 'image|bitmap|pixmap'; then
	printf "Input file is not an image.\n"
	exit
elif [ "$2" = "bandreject" ]; then
	gfn $1 && varset $1
	printf "Reject Frequency: " ; read cv1
	printf "Width: " ; read cv2
	ffcmd="ffmpeg -y -f alaw -i $ucimg -af bandreject=f=$cv1:width_type=h:w=$cv2 -f alaw $inter"
elif [ "$2" = "highpass" ]; then
	gfn $1 && varset $1
	varset $1
	printf "Cutoff frequency: " ; read cv1
	ffcmd="ffmpeg -y -f alaw -i $ucimg -af highpass=f=$cv1 -f alaw $inter"
elif [ "$2" = "lowpass" ]; then
	gfn $1 && varset $1
	varset $1
	printf "Cutoff frequency: " ; read cv1
	ffcmd="ffmpeg -y -f alaw -i $ucimg -af lowpass=f=$cv1 -f alaw $inter"
else
	printf "I don't know this filter!\n"
	exit 76
fi

# <======================= checks


# corruption =============>

convert $1 -depth 8 -alpha off $ucimg
sleep 1

# save the header as base64 for later manipulations
header=$(head -c54 $ucimg | base64)

# execute the ffmpeg command
$ffcmd

# restoring the header
bytes=$(wc -c $ucimg | awk '{print $1}')

printf $header | base64 -d  > $cimg
head -c $bytes $inter | tail -c $bytes >> $cimg

convert $cimg "$fname".png
sleep 1

# <============= corruption

# cleanup & debug info
if [ "$3" = "debug" ]; then
	printf "hash> $hash\nTemp files:\nffcmd> $ffcmd\nucimg> $ucimg\ninter> $inter\ncimg> $cimg\n"
else
rm $ucimg $cimg $inter
fi
