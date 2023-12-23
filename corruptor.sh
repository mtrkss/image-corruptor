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

format="alaw" # format for ffmpeg (changing this WILL cause even more corruption)

# help & licensing
case "$*" in
	"" | *-"hel"*) # *"-h"* was triggering the help message all the time so i had to remove it.
		cat <<'<-stob'

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

<-stob
		exit 0
		;;
	*"licens"*)
		head -n15 $0 | tail -n14 | sed 's/\#//g'
		exit 0
	;;
esac

# set some variables =========>
switches() {
local args="$*"	# args = all switches you provide
local IFS=" "	# i ughhh

# loop through each arg
for arg in $args; do
	case $arg in
		-i=*) input="${arg#*=}" ;;	# self-explanatory
		-o=*) output="${arg#*=}" ;;
		-f=*) filter="${arg#*=}" ;;
		-s=*) cset="${arg#*=}" ;;
		--debug) debug="y" ;;
		*) ;;  # ignore any other args
	esac
done
}
switches "$*"

# functions ==================>
varset() {
hash=$(sha1sum $1 | head -c10)
ucimg=/tmp/ucimg-"$hash".bmp
cimg=/tmp/cimg-"$hash".bmp
inter=/tmp/inter-"$hash".raw
}

error() {
printf "%s\n" "Error: $1"
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
if [ "$debug" = "y" ]; then
	$1
	printf "\ninput> $input\noutput> $output\nfilter> $filter\ncset> $cset\nhash> $hash\n\nTemp files:\nffcmd> $ffcmd\nucimg> $ucimg\ninter> $inter\ncimg> $cimg\n\nPress Enter to Continue. " && read nothing
	$2
fi
}

rval(){
printf "reject frequency? " && read fv1
}

# HELL... ====================>
ffset() {
fv1="$cset"
basecmd="ffmpeg -y -f $format -i $ucimg -af"

if [ -z "$fv1" ] && ! [ "$filter" = "custom" ]; then
	rval
fi

case "$filter" in
	"highpass")
		ffcmd="$basecmd volume=-0.15dB,highpass=f=$fv1 -f $format $inter"
		;;
	"lowpass")
		ffcmd="$basecmd volume=-0.15dB,lowpass=f=$fv1 -f $format $inter"
		;;
	"custom")
		if [ -z "$cset" ]; then
			error 'Please specify a filter and its settings.
Example: -s="acrusher=bits=16:samples=64"' 78
		else
			ffcmd="$basecmd $cset -f alaw $inter"
		fi
		;;
		*)
	error "I don't know this filter!" 76
	;;
esac
}
# setting the ffcmd (many checks included)
if [ -z "$input" ]; then
	error "I need an input image!" 66
elif [ -z "$filter" ]; then
	error "Please choose a filter as the -f= option. Available filters:
bandreject, highpass, lowpass, contrast, custom." 78
else
	getfile "$input"
	if [ -z "$output" ]; then
		output="${hash}.png"
		printf "Output not specified! Defaulting to $(pwd)/${output}\n"
	fi
	ffset
	debug
fi

# corruption =================>
convert $input -depth 8 -alpha off $ucimg
sleep 1

$ffcmd

# restoring the header
head -c54 $ucimg > $cimg
bytes=$(expr $(wc -c $inter | awk '{print $1}') - 54) # this is AWKward
tail -c $bytes $inter >> $cimg

# convert the resulting image to png
convert $cimg $output

# cleanup & debug info
if [ "$debug" = "y" ]; then
	debug
else
	rm $ucimg $cimg $inter
fi
