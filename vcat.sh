#!/bin/bash

# concatenate several video files using stream copy (fast and lossless)

begin=${1:11:5}_${1:17:5}
file="input_list.txt"
rm $file

i=0
while [ -n "$1" ] ; do
    echo "adding $1"
    echo "file '$1'" >> $file
    i=$(( $i + 1 ))
    shift
done

ffmpeg -f concat -i $file -c:v copy -c:a copy vcat_${begin}.mp4

rm $file