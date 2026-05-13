#!/bin/bash
# TTS生成脚本 — 使用 edge-tts 按页分段或逐句生成音频
# 用法：bash tts-generate.sh <voice> <strategy> <script_file>
#   voice: zh-CN-YunjianNeural (科技/激情) | zh-CN-YunyangNeural (专业) | zh-CN-XiaoxiaoNeural (温暖) | zh-CN-YunxiNeural (轻快)
#   strategy: page (按页分段) | sentence (逐句)
#   script_file: tts_script.md 路径

VOICE="${1:-zh-CN-YunjianNeural}"
STRATEGY="${2:-page}"
SCRIPT_FILE="${3:-tts_script.md}"
OUTDIR="tts"

mkdir -p "$OUTDIR"

if [ "$STRATEGY" = "page" ]; then
  echo "=== 按页分段生成 TTS (voice: $VOICE) ==="
  # 从 tts_script.md 中提取每段时间段的文本，按 [start-end] 分段
  # 每页生成一个 mp3
  # 手工指定各段文本（从 tts_script.md 读取）
  # 示例：
  # edge-tts --voice "$VOICE" --text "第一页文本。" --write-media "$OUTDIR/s01.mp3"
  # edge-tts --voice "$VOICE" --text "第二页文本。" --write-media "$OUTDIR/s02.mp3"
  echo "请从 tts_script.md 提取每段文本，逐段调用 edge-tts"
  echo "或使用并行生成：每批4个，如："
  echo "  edge-tts --voice '$VOICE' --text '...' --write-media '$OUTDIR/s01.mp3' &"
  echo "  edge-tts --voice '$VOICE' --text '...' --write-media '$OUTDIR/s02.mp3' &"
  echo "  wait"
elif [ "$STRATEGY" = "sentence" ]; then
  echo "=== 逐句生成 TTS (voice: $VOICE) ==="
  echo "将 tts_script.md 中的文本按句子拆分，每句一个mp3"
  echo "  edge-tts --voice '$VOICE' --text '第一句话。' --write-media '$OUTDIR/e01.mp3'"
  echo "  edge-tts --voice '$VOICE' --text '第二句话。' --write-media '$OUTDIR/e02.mp3'"
  echo "可并行生成（每批4个），大幅提速"
else
  echo "Unknown strategy: $STRATEGY (use 'page' or 'sentence')"
  exit 1
fi
