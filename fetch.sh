#!/bin/bash

#set -x

# param1: optional ip address for source camera
# param2: force number of hours to resume collect instead of using last update time

# relative directories
RAW=raw
MEDIA=media
VIDEOS=videos
SNAPSHOTS=snapshots
MAX_KB=4800 # kbps to limit CPU load on this small hardware
DELAY_REMOVE_MINUTES=3000

host="192.168.1.10"
suffix=""
timeout=25
beginTS=$(date +%s)

# return the number of minutes since last update or long ago if not found
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
function fetchNew() {
	cat $2 | while read d ; do
		local now=$(date +%s)
		local elapsed=$(( ($now - $beginTS) / 60 ))
		echo "($elapsed min) fetching files from $d"
		mkdir -p $3/$(basename $d)
		scp -o ConnectTimeout=$timeout -l $MAX_KB $1/$d/* $3/$(basename $d)

		if [ "$?" != 0 ] ; then
			echo "error while fetching videos"
			exit 1
		fi

		updateMedia
		updatePlaylist
		local localTime=$(date -d "${d:0:4}-${d:5:2}-${d:8:2}T${d:11:2}:00:00Z" "+%Y%m%d%H%M")
		setLastUpdate $localTime
	done
}

function updateMedia() {
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
	cd - > /dev/null
}

function updatePlaylist() {
	if [ -n "$lastDay" ] ; then
		./playlist.sh ${lastDay} ${suffix}
		./playlist.sh ${lastDay}
	fi
}

# param 1 date as CCYYMMDDhhmm
function setLastUpdate() {
	# last_update_suffix.txt will be used on next fetch to determine since when files have to retrieved
	touch -t "$1" last_update${suffix}.txt
}

function removeRemoteFiles() {
	ssh -o ConnectTimeout=$timeout root@${host} "find www/record -type f -name '*.mp4' -mmin +$DELAY_REMOVE_MINUTES -delete"
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
	# echo "resuming from last update: $since"
else
	since=$(( $1 * 60 ))
fi

echo "collect files since $since minutes ("$(( $since / 60 )) "hours)"

begin=$(date "+%Y%m%d%H%M")

ssh -o ConnectTimeout=$timeout root@${host} "find www/record -type f -name '*.mp4' -mmin -$since" | sed "s;www/record/;;g" > remote_files.txt
echo $( cat remote_files.txt | wc -l ) "videos"

find $RAW/$VIDEOS -type f -name '*.mp4' | sed "s;$RAW/$VIDEOS/;;g" > local_files.txt
diff remote_files.txt local_files.txt | grep '<' | sed "s/< //" > new_files.txt

cat new_files.txt | cut -d/ -f 1 | sort | uniq > new_directories.txt
fetchNew "scp://root@${host}/www/record" new_directories.txt $RAW/$VIDEOS

if [ $? != 0 ] ; then
	exit 1
fi

if [ -n "$lastUpdateTS" ] ;then
	lastUpdate=$(date -d @${lastUpdateTS} +"%Y-%m-%d")
fi

# snapshots snapshots/YYYY-MM-DD/*.jpg, also add the first day even if no videos were recorded after the update
days=$(echo "$lastUpdate" | cat remote_files.txt - | cut -dD -f 1 | tr "YM" "--" | grep -vP ^$ | sort | uniq)
for d in $days ; do
	echo "copy snapshots of day $d"
	mkdir -p $RAW/$SNAPSHOTS/$d
	scp -o ConnectTimeout=$timeout -l $MAX_KB scp://root@${host}/snapshot/${d}/* $RAW/$SNAPSHOTS/$d

	if [ "$?" != 0 ] ; then
		echo "error while fetching snapshots"
		exit 1
	fi
done

# copy snapshots to media
cd $RAW
find $SNAPSHOTS -type f -mmin -$since > new_snapshot_files.txt # snapshots/2024-09-19/2024-09-19_06_10.jpg to media/YYYY-MM-DD/snapshots/YYYY_MM_DD_HH_MM.jpg
for f in $(cat new_snapshot_files.txt) ; do
	dateDir=${f:10:4}-${f:15:2}-${f:18:2}
	dateFile=${f:10:4}_${f:15:2}_${f:18:2}
	timeFile=${f:32:2}_${f:35:2}
	mkdir -p ../$MEDIA/${dateDir}/snapshots
	cp $f ../$MEDIA/${dateDir}/snapshots/${dateFile}_${timeFile}.jpg
done
cd - > /dev/null

# clean up old files in raw directory
find $RAW -type f -mtime +15 -delete
find $RAW -type d -empty -delete

rm *_files.txt new_directories.txt

setLastUpdate $begin
removeRemoteFiles

./visits.sh $dateDir
