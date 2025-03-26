#!/bin/bash

# display the number of videos for each hour/day
# ./visits.sh             -> display all media video counts per day
# ./visits.sh -h          -> display all media video counts per hour for all days globally
# ./visits.sh 2025-03-24  -> display all media video counts per hour for specified day

hours=0
days="*-*-*"

while [ -n "$1" ] ; do
    case $1 in
    -h)
        hours=1
        days='*-*-*';;
    *)
        hours=1
        days="$1";;
    esac
    shift
done

if [ $hours = 1 ]; then
    for h in $(seq -w 5 21); do
        count=$(find media -path "media/$days/${h}_*_*_dur*.mp4" | wc -l)
        l="$h : "
        for i in $(seq 1 $count) ; do
            l=${l}"•"
        done
        if [ $count != 0 ] ; then
            l="$l $count"
        fi
        echo $l
    done
else
    cd media
    for d in $(find . -maxdepth 1 -path "$days") ; do
        dayCount=$(find ${d} -name "*_dur*.mp4" | wc -l)
        l="$d: "
        for i in $(seq 1 $dayCount) ; do
            l=${l}"•"
        done

        echo "$l $dayCount"
    done
    cd -
fi