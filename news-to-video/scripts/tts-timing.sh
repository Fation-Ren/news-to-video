#!/bin/bash
# TTS Timing Reference 生成脚本 — 记录每段时长 + 生成锚点表 + 合并音频
# 用法：bash tts-timing.sh <tts_dir> <output_dir>
#   tts_dir: TTS分段文件所在目录（如 tts/）
#   output_dir: 输出目录（如 composition/）

TTS_DIR="${1:-tts}"
OUT_DIR="${2:-composition}"

echo "# TTS Timing Reference — 逐句锚点表"
echo ""

# 步骤1：记录每段时长
echo "## 逐段锚点"
echo "| 段 | 文件 | 起始(s) | 时长(s) | 结束(s) |"
echo "|----|------|---------|---------|---------|"

acc=0
for f in "$TTS_DIR"/*.mp3; do
  d=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$f")
  fname=$(basename "$f")
  end=$(echo "$acc + $d" | bc)
  printf "| %s | %s | %.2f | %.2f | %.2f |\n" "${fname%%.mp3}" "$fname" "$acc" "$d" "$end"
  acc=$end
done

total=$acc
echo ""
echo "总时长：${total}s"

# 步骤2：合并音频
mkdir -p "$OUT_DIR"
> "$TTS_DIR/list.txt"
for f in "$TTS_DIR"/*.mp3; do
  echo "file '$PWD/$f'" >> "$TTS_DIR/list.txt"
done
ffmpeg -f concat -safe 0 -i "$TTS_DIR/list.txt" -c copy "$OUT_DIR/output.mp3" -y 2>/dev/null
echo ""
echo "合并完成：$OUT_DIR/output.mp3 ($(ls -lh "$OUT_DIR/output.mp3" | awk '{print $5}'))"
