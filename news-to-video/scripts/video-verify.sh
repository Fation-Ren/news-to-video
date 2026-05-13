#!/bin/bash
# 视频输出验证脚本
# 用法：bash video-verify.sh <video.mp4>

VIDEO="${1:-output.mp4}"

echo "=== Stream Info ==="
ffprobe -v quiet -show_entries stream=codec_type,codec_name,width,height,channels -of csv=p=0 "$VIDEO"
# 必须输出: h264,video + aac,audio,2

echo ""
echo "=== Duration ==="
d=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$VIDEO")
printf "Duration: %.2fs\n" "$d"

echo ""
echo "=== Volume ==="
ffmpeg -i "$VIDEO" -af "volumedetect" -f null - 2>&1 | grep mean_volume
# mean_volume 应在 -20 到 -10 dB 之间

echo ""
echo "=== File Size ==="
ls -lh "$VIDEO" | awk '{print "Size: " $5}'
