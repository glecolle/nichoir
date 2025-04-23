# Nichoir

## Description

Tools for Yi-home cameras, to be exectued from a remote computer.

New scripts in addition to (https://github.com/roleoroleo/yi-hack-Allwinner-v2)[Yi Hack AllWinner v2]:
 - **fetch.sh**: incremental fetch of videos from the camera, reduce transfer latency and avoid copying twice the same files to save time (even though rsync is not installed). Can handle several cameras using suffixes.
 - **cleanup.sh**: improved embedded cleanup, must be enabled using cron from Yi-Hack web interface with ```1 * * * * /tmp/sd/yi-hack/script/clean_records.sh```
 - **playlist.sh**: creates playlists for each day after fetching to easily view the videos of the day.
 - **snapshot.sh**: take snapshots every 10 minutes, must be enabled from Yi-Hack web interface with ```*/10 6-20 * * * /tmp/sd/yi-hack/script/snapshot.sh```
 - **timelapse.sh**: easy timelapse creation based on snapshots, not embedded on the camera (hardware is not designed for video edition).

 ## Installation

 You must first install Yi-Hack and then you can add these scripts.

 You should not overwrite scripts files, but **system.sh** contains an intersting modification at line 184:

    # reduce wartermark visibility (HD)
    if [ -f /tmp/sd/yi-hack/main.bmp ] ; then
        mount --bind /tmp/sd/yi-hack/main.bmp /home/app/main_kami.bmp
    fi

This replaces the watermark logo within the videos by the main.bmp image (50/50 alpha blend). You may edit the main.bmp image to have a closer match to your final picture, for general purpose, medium grey should be fine.
