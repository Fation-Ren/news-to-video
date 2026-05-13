#!/bin/bash
# 音频预处理脚本 — 检查格式 + 转换 + 复制到 composition/
# 用法：bash prepare-audio.sh <tts_audio> <bgm_dir> <output_dir>

TTS_AUDIO="${1:-output.mp3}"
BGM_DIR="${2:-bgm}"
OUT_DIR="${3:-composition}"

echo "=== 音频预处理 ==="

# 1. 检查 TTS 音频格式
echo ""
echo "[1/4] 检查 TTS 音频格式..."
ffprobe -v quiet -show_entries stream=codec_name,channels,sample_rate "$TTS_AUDIO" 2>/dev/null
if [ $? -ne 0 ]; then
  echo "错误：无法读取 $TTS_AUDIO"
  exit 1
fi

# 2. 检查时长
DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$TTS_AUDIO")
printf "  时长: %.2fs\n" "$DUR"

# 3. 创建输出目录并复制文件
echo ""
echo "[2/4] 创建 composition 目录..."
mkdir -p "$OUT_DIR/bgm"

echo "[3/4] 复制 TTS 音频..."
cp "$TTS_AUDIO" "$OUT_DIR/output.mp3"
echo "  $OUT_DIR/output.mp3"

echo "[4/4] 复制 BGM 文件（实体文件，非 symlink）..."
if [ -d "$BGM_DIR" ] && [ "$(ls -A "$BGM_DIR" 2>/dev/null)" ]; then
  cp "$BGM_DIR"/*.mp3 "$OUT_DIR/bgm/"
  ls -lh "$OUT_DIR/bgm/"
else
  echo "  警告：$BGM_DIR 目录为空或不存在"
fi

echo ""
echo "=== 音频预处理完成 ==="
echo "TTS: $OUT_DIR/output.mp3 ($(ls -lh "$OUT_DIR/output.mp3" | awk '{print $5}'))"
echo "BGM: $OUT_DIR/bgm/"
