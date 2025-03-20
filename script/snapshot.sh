#!/bin/bash

# add to yi-hack using cron: */10 5-20 * * * /tmp/sd/script/snapshot.sh

snapdir=/tmp/sd/yi-hack/snapshot
dir=$snapdir/$(date +%Y-%m-%d)
file=$(date +%Y-%m-%d_%H_%M.jpg)

mkdir -p $dir

# version web
#wget http://127.0.0.1/cgi-bin/snapshot.sh\?res=high\&watermark=no -O $dir/$file

# version sans doute moins gourmande en ressources:
YI_HACK_PREFIX="/tmp/sd/yi-hack"
MODEL_SUFFIX=$(cat $YI_HACK_PREFIX/model_suffix)
imggrabber -m $MODEL_SUFFIX -r high -w > $dir/$file
