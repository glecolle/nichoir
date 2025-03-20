#!/bin/bash

if [ -z "$1" ] ; then
    echo "Usage: $(basename $0) <dir1> <dir2> ..."
    echo "Create a playlist file for each directory"
    exit
fi

while [ -n "$1" ] ; do
    targetDir=$1
    shift

    cd $targetDir
    playlistFile=playlist.m3u
    echo "#EXTM3U" > ${playlistFile}

    ls *dur*.mp4 >> $playlistFile
    cd - > /dev/null

    echo "created playlist $playlistFile"
done