# Nichoir

## Description

Tools for Yi-home cameras, to be exectued from a remote computer.

New scripts have been added compared to Yi Hack AllWinner v2:
 - fetch.sh: incremental fetch of videos from the camera, reduce transfer latency and avoid copying twice the same files to save time (even though rsync is not installed).
 - cleanup.sh: improved cleanup.
 - timelapse.sh: easy timelapse creation based on respositories with ffmpeg but not embedded on the camera (hardware is not designed for video edition).
 - playlist.sh: creates playlists for each day after fetch to easily view today's videos.
