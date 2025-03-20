#!/bin/sh

MAX_AGE_DAYS=14

find /tmp/sd/record -path '*D0[012345]H/E*.mp4' -delete
find /tmp/sd/record -path '*D2[123]H/E*.mp4' -delete

find /tmp/sd/record -mtime $MAX_AGE_DAYS -delete -empty
find /tmp/sd/yi-hack/snapshot -mtime $MAX_AGE_DAYS -delete -empty
