#!/bin/bash

if [ -z "$1" ]; then
    echo "$(basename $0) fps [minSizeKB] directories "
    echo "fps:  the number of frames per second, higher number will reduce the duration of the video."
    echo "directories: copy files from directories, rename them as a sequence of images and create a video file, use existing images in timelapse dir if omitted."
    echo "minSizeKB: remove files smaller than this size in KiBi (150 is a good choice)."
    exit
fi

mkdir -p timelapse

fps=$1
shift

minSizeKB=0
if [[ "$1" =~ ^[0-9]+$ ]] ; then
    minSizeKB=$1
    shift
fi

if [ -n "$1" ] ; then
    rm -f timelapse/img*.jpg

    echo "copying images"
    while [ -n "$1" ] ; do
        echo "copy images from $1"
        cp "$1"/*.jpg timelapse
        shift
    done

    nbSmall=$(find timelapse -type f -name "*.jpg" -size -${minSizeKB}k | wc -l)
    echo "removing ${nbSmall} files smaller than ${minSizeKB} KiBi"
    find timelapse -type f -name "*.jpg" -size -${minSizeKB}k -delete

    echo "renaming images"
    files=$(ls timelapse/*.jpg)
    i=1
    for f in $files ; do
        mv $f $(dirname $f)/img$(printf %07d $i).jpg
        i=$(( i + 1 ))
    done

    echo "images files copied to timelapse directory and renamed as a sequence"
fi

ffmpeg -framerate $fps -i "timelapse/img%07d.jpg" -c:v libx264 -crf 15 -preset medium timelapse_${fps}fps.mp4
echo "created timelapse_${fps}fps.mp4"
