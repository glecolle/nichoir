#!/bin/sh

# Params:
# - $1 = $YI_HACK_PREFIX
# - $2 = $FFMPEG_RTSP_STREAM_URL
# - $3 = $FFMPEG_RTSP_CLIENT_IP
# - $4 = $FFMPEG_RTSP_STREAM_NAME

is_ffmpeg_rtsp_started()
{
    if [[ "`ps | grep "$1/bin/ffmpeg_rtsp" | grep -v "grep" | awk 'NR==1{print $1}'`" == "" ]] ; then
        echo "no"
    else
        echo "yes"
    fi 
}

if [[ "$(is_ffmpeg_rtsp_started)" == "no" ]] ; then
    . $1/etc/ffmpeg_rtsp.conf

    IP_RTSP=`ping -c 1 $3 | awk 'FNR == 1' | sed 's/[ \(\)]/ /g' | cut -d' ' -f4`

    $1/bin/ffmpeg_rtsp -i $2 -c:v copy -c:a copy -rtsp_transport tcp -f rtsp rtsp://$IP_RTSP/$4 &
    
    sleep 10

    if [[ "$(is_ffmpeg_rtsp_started)" == "yes" ]] ; then
        echo "FFMpeg launched successfully"
        exit 0
    fi

    echo "FFMpeg: error on launch"
    exit 1
fi

echo "FFMpeg is already started"
exit 0

