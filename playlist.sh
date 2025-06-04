#!/bin/bash

if [ -z "$1" ] ; then
    echo "Usage: $(basename $0) <dir1> <suffix>"
    echo "Create a playlist file for all videos within a directory"
    exit
fi


targetDir=$1
suffix=$2

cd $targetDir
playlistFile=playlist${suffix}.m3u
echo "#EXTM3U" > ${playlistFile}

ls *dur*${suffix}.mp4 >> $playlistFile
cd - > /dev/null

echo "updated playlist $playlistFile in $targetDir (for suffix $suffix)"
