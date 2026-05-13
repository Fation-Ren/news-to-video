# 渲染前自检

## 1. Lint（必须0错误）
```bash
npx hyperframes lint composition/
```
常见错误修复：
- `overlapping_clips_same_track` → BGM用不同 track-index
- `invalid_inline_script_syntax` → `node --check` 检查JS
- `scene_layer_missing_visibility_kill` → 补充 `tl.set(visibility:"hidden")`

## 2. Validate
```bash
npx hyperframes validate composition/
```

## 3. 预检（运行 preflight-check.sh）
```bash
bash scripts/preflight-check.sh composition/
```

## 4. 人工确认清单

| # | 检查项 | 验证方法 |
|---|--------|---------|
| 1 | 所有音频是实体文件（非symlink） | `ls -la composition/bgm/` |
| 2 | TTS音频路径为 `src="output.mp3"` | 检查 `<audio id="tts">` |
| 3 | BGM使用不同 `data-track-index` | 统计唯一 track-index 数 |
| 4 | 同 track-index 的BGM无时间重叠 | 核对 start/duration |
| 5 | 字幕文本与 tts_script.md 一致 | diff 对照 |
| 6 | 字幕时长≥2.0s，长文本3.5-4s | 检查 caps 数组 d 值 |
| 7 | 每场景边界有过渡 | 过渡数 = 场景数-1 |
| 8 | 每过渡有 `visibility:hidden` kill | `grep "visibility.*hidden"` |
| 9 | 场景1默认可见，场景2+ `opacity:0` | 检查 scene div style |
| 10 | `window.__timelines["id"]` = root `data-composition-id` | 核对两处ID |

全部通过 → 渲染。

## 渲染
```bash
npx hyperframes render composition/ --output video.mp4
```
耗时约30-70s（取决于时长和核数）。

## 输出验证
```bash
bash scripts/video-verify.sh video.mp4
```
必须：h264+video + aac+audio+2ch / 时长=锚点表±0.1s / mean_volume在-20到-10dB
