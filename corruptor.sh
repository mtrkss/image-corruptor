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

unset input output filter cset imgfmt format arate complex debug lavfi alpha depth

format=alaw # format for ffmpeg (changing this WILL cause even more corruption)
arate=44100
depth=8
hsize=54

if [ "$(uname -o)" = Android ] || [ "$(uname -o)" = Toybox ] # only use quotes for uname to treat the whole output as a single string
then tmpdir=./tmp
else tmpdir=/tmp/imgcorrupt
fi

# help & licensing
case "$*" in
	"" | *-"hel"*) cat <<stob

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
$ $0 -i=input.png -o=output.png -f=lowpass -s=7000
$ $0 -i=input.png -o=output.png -f=custom -s="acrusher=bits=16:samples=64:mix=0.2,lowpass=f=7000,volume=-2dB"

stob
exit 0 ;;
	*"licens"*) sed -n '2,15{s/^#//;p}' $0;exit 0 ;;
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
		-s=*) cset="${arg#*=}" ;;
		-a=*) format="${arg#*=}" ;;
		-r=*) arate="${arg#*=}" ;;
		-d=*) depth="${arg#*=}" ;;
		-au=*) complex="${arg#*=}" ;;
		--debug) debug=y ;;
		--lavfi) lavfi=y ;;
		--alpha) alpha=y ;;
		--limit) limit=y ;;
		*) ;;  # ignore any other args
	esac
done
}
switches "$*"

# functions ==================>
varset() {
hash=$(md5sum "$1"|head -c10)
ucimg=${tmpdir}/ucimg-$hash.bmp
cimg=${tmpdir}/cimg-$hash.bmp
inter=${tmpdir}/inter-$hash.raw
}

error() {
printf "Error: $1\n"
exit "$2"
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
cat <<OwO
Debug info

Internal variables:
hash>	$hash
ucimg>	$ucimg
cimg>	$cimg
inter>	$inter
ffcmd>	$ffcmd

User input:
input>	$input
output>	$output
filter>	$filter
format>	$format
cset>	$cset
au> 	$complex
lavfi>	$lavfi
arate> 	$arate
limit>	$limit
OwO
read nothing
}

rval() {
printf "Filter frequency: "
read fv1
}

chkapp() {
printf "Searching for $1...\n"
which $1 2>/dev/null&&printf "$1 found\n\n"||error "$1 not found! Please install the $2 package." 1
}

ffwrong() {
printf "FFmpeg exited with a non-0 code!\nContinue? (may be risky) [Y/n]: "
read ans;echo $ans|grep -E [nN]>/dev/null&&exit 1
}

alias cls='[ -z $debug ]&&clear'

chkapp ffmpeg ffmpeg
chkapp convert ImageMagick

## check for and create a temporary directory
[ -d "$tmpdir" ] || mkdir "$tmpdir" || error "Can't create a temporary directory!" 1

# aeugh
ffset() {
fv1="$cset"
if [ -z $complex ]
then basecmd="ffmpeg -y -f $format -ar $arate -i $ucimg -af"
else basecmd="ffmpeg -y -f $format -ar $arate -i $ucimg $([ ! -z $lavfi ]&&printf %s"-f lavfi") -i $complex -filter_complex"
fi

[ -z "$fv1" ] && [ "$filter" != custom ] && rval

case "$filter" in
	"highpass") ffcmd="$basecmd volume=-0.15dB,highpass=f=$fv1 -f $format $inter" ;;
	"lowpass") ffcmd="$basecmd volume=-0.15dB,lowpass=f=$fv1 -f $format $inter" ;;
	"custom") if [ ! -z "$cset" ]; then ffcmd="$basecmd $cset -f $format $inter"; else error 'Please specify a filter and its settings.\nExample: -s="acrusher=bits=16:samples=64:mix=0.2"' 78; fi ;;
		*) error "I don't know this filter!" 76 ;;
esac
}
# setting the ffcmd
if [ -z "$input" ]; then
	error "I need an input image!" 66
elif [ -z "$filter" ]; then
	error "Please choose a filter as the -f= option. Available filters:
highpass, lowpass, custom." 78
else
	getfile "$input"
	if [ -z "$output" ]; then
		output="${hash}.png"
		printf "Output not specified! Defaulting to $(pwd)/${output}\n"
	fi
	ffset
fi

# corruption
[ ! -z $debug ] && printf "Everything correct here?\n" && debug
convert "$input" -depth $depth -alpha $([ -z $alpha ]&&printf %soff||printf %son) $ucimg

$ffcmd || ffwrong && cls

## restoring the header
head -c$hsize $ucimg>$cimg
if [ ! -z $limit ]
then tail -c+$(($hsize+1)) $inter|head -c$(($(wc -c<$ucimg)-$hsize))>>$cimg
else tail -c $(($(wc -c<$inter)-$hsize)) $inter>>$cimg
fi

## convert the resulting image to png
convert $cimg "$output"

# cleanup & debug info
if [ ! -z $debug ]
then debug
else printf "Cleaning up...\n"
	 rm -rv "$tmpdir" && printf "Done\n\n"
fi
