#!/bin/bash

#set -x

# param1: optional ip address for source camera
# param2: force number of hours to resume collect instead of using last update time

# relative directories
RAW=raw
MEDIA=media
VIDEOS=videos
SNAPSHOTS=snapshots

host="192.168.1.10"
suffix=""
timeout=5

# return the number of minutes since last download or long ago if not found
function latestFile() {
	local f="last_update${suffix}.txt"

	if [ ! -e "$f" ] ; then
		echo $(( 60 * 24 * 14 ))
		return
	fi

	local since=$(stat --format=%Y $f)
	local now=$(date +%s)
	echo $(( ($now - $since) / 60))
}

# param1 remote directory command and prefix
# param2 file containing the directories to copy like 2024Y09M04D06H
# param3 targetDir local directory
function copyNew() {
	cat $2 | while read d ; do
		mkdir -p $3/$(basename $d)
		scp -o ConnectTimeout=$timeout $1/$d/* $3/$(basename $d)
	done
}

cd $(dirname $0)

if [ ! -d $RAW/$VIDEOS ]; then
	mkdir -p $RAW/$VIDEOS
fi
if [ ! -d $RAW/$SNAPSHOTS ]; then
	mkdir $RAW/$SNAPSHOTS
fi
if [ ! -d $VIDEOS ]; then
	mkdir $VIDEOS
fi
if [ ! -d $SNPASHOTS ]; then
	mkdir $SNAPSHOTS
fi

if [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	host=$1
	suffix=$2
	RAW="${RAW}${suffix}"
	echo "fetching from $host with suffix $suffix"
	shift
	shift
fi

if [ -z "$1" ] ; then
	since=$(latestFile)
	lastUpdateTS=$(stat --format=%Y last_update${suffix}.txt)
	echo "resuming from last update"
else
	since=$(( $1 * 60 ))
fi
echo "collect files since $since minutes ("$(( $since /60 )) "hours)"

ssh -o ConnectTimeout=$timeout root@${host} "find www/record -type f -name '*.mp4' -mmin -$since" | sed "s;www/record/;;g" > remote_files.txt
echo $( cat remote_files.txt | wc -l ) " videos"

#cat remote_files.txt | grep -vP '(0[01234]|2[123])H' | grep -vP "05H/E200M00S60.mp4" > filtered_remote_files.txt
cat remote_files.txt > filtered_remote_files.txt
#echo $( cat filtered_remote_files.txt | wc -l ) "new videos to copy"

find $RAW/$VIDEOS -type f -name '*.mp4' | sed "s;$RAW/$VIDEOS/;;g" > local_files.txt
diff filtered_remote_files.txt local_files.txt | grep '<' | sed "s/< //" > new_files.txt

cat new_files.txt | cut -d/ -f 1 | sort | uniq > new_directories.txt
copyNew "scp://root@${host}/www/record" new_directories.txt $RAW/$VIDEOS

if [ -n "$lastUpdateTS" ] ;then
	lastUpdate=$(date -d @${lastUpdateTS} +"%Y-%m-%d")
fi

# snapshots snapshots/YYYY-MM-DD/*.jpg, also add the first day even if no videos were recorded after the update
days=$(echo "$lastUpdate" | cat remote_files.txt - | cut -dD -f 1 | tr "YM" "--" | grep -vP ^$ | sort | uniq)
for d in $days ; do
	echo "copy snapshots of day $d"
	mkdir -p $RAW/$SNAPSHOTS/$d
	scp -o ConnectTimeout=$timeout scp://root@${host}/snapshot/${d}/* $RAW/$SNAPSHOTS/$d
done

# copy videos to media -> 08_06_00_dur60.mp4
cd $RAW
find $VIDEOS -type f -mmin -$since > new_video_files.txt # videos/2024Y09M18D08H/E206M00S60.mp4
lastDay=""
for f in $(cat new_video_files.txt) ; do
	dayDir=$MEDIA/${f:7:4}-${f:12:2}-${f:15:2}
	if [ -n "$lastDay" ] && [ "$dayDir" != "$lastDay" ] ; then
		../playlist.sh ${lastDay}
	fi
	lastDay="$dayDir"

	mkdir -p ../$dayDir

	# translate utc file name to local time
	utc="${f:7:4}-${f:12:2}-${f:15:2}T${f:18:2}:${f:24:2}:${f:27:2}Z"
	localTime=$(date -d "$utc" "+%Y-%m-%dT%H:%M:%S") # 2024-10-05T14:10:00
	destFile="${localTime:11:2}_${localTime:14:2}_${localTime:17:2}_dur${f:30:2}${suffix}.mp4"
	cp $f ../${dayDir}/${destFile}
done
cd -

if [ -n "$lastDay" ] ; then
	./playlist.sh ${lastDay} ${suffix}
	./playlist.sh ${lastDay}
fi

# copy snapshots to media
cd $RAW
find $SNAPSHOTS -type f -mmin -$since > new_snapshot_files.txt # snapshots/2024-09-19/2024-09-19_06_10.jpg to media/YYYY-MM-DD/snapshots/YYYY_MM_DD_HH_MM.jpg
for f in $(cat new_snapshot_files.txt) ; do
	dateDir=${f:10:4}-${f:15:2}-${f:18:2}
	dateFile=${f:10:4}_${f:15:2}_${f:18:2}
	timeFile=${f:32:2}_${f:35:2}
	mkdir -p ../media/${dateDir}/snapshots
	cp $f ../media/${dateDir}/snapshots/${dateFile}_${timeFile}.jpg
done
cd -

# clean up old files in raw directory
find $RAW -type f -mtime +15 -delete
find $RAW -type d -empty -delete

# last_update_suffix.txt will be used on next fetch to determine since when files have to retrieved
if [ $(stat -c %s remote_files.txt) == 0 ] ; then
	echo "ignoring this update since no files were fetched"
else
	mv remote_files.txt "last_update${suffix}.txt"
fi
rm *_files.txt new_directories.txt

./visits.sh $dateDir
