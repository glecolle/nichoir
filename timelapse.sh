#!/bin/bash

if [ -z "$1" ]; then
    echo "$(basename $0) fps_duration [minSizeKB] directories "
    echo "fps_duration:  the number of frames per second "30" or the duration "10s" to compute the number of fps to match the target duration in seconds."
    echo "minSizeKB: remove files smaller than this size in KiBi (165 is a good choice)."
    echo "directories: copy files from directories, rename them as a sequence of images and create a video file, use existing images in timelapse dir if omitted."
    exit
fi

mkdir -p timelapse

fps=$1
shift

targetFile="timelapse_${fps}.mp4"

minSizeKB=0
if [[ "$1" =~ ^[0-9]+$ ]] ; then
    minSizeKB=$1
    shift
fi

if [ -n "$1" ] ; then
    rm -f timelapse/img*.jpg

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

if [[ "$fps" =~ [0-9]+s ]] ; then
    nb=$(ls timelapse/*.jpg | wc -l)
    duration=$(echo $fps | tr "s" " ")
    fps=$(( $nb / $duration ))
    echo "using $nb files to target a duration of ${duration}seconds, fps is $fps"
else
    fps=$1
fi

ffmpeg -framerate $fps -i "timelapse/img%07d.jpg" -c:v libx264 -crf 15 -preset medium -r 30 $targetFile
echo "created $targetFile"
