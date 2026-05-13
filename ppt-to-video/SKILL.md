---
name: ppt-to-video
description: |
  Convert PPT HTML slides + TTS audio + BGM into a HyperFrames video composition.
  Use this skill whenever the user wants to: create a video from presentation slides,
  synthesize slides with voiceover into MP4, add captions synced to TTS audio,
  convert PPT HTML to video with background music, or produce narrated video content
  from existing HTML presentations. Triggers on: "合成视频", "生成视频", "slides to video",
  "PPT转视频", "add voiceover to slides", "make video from HTML", "render slides as video".
---

# PPT-to-Video: HTML Slides → HyperFrames Video

将 HTML 幻灯片合成为 MP4 视频（TTS+BGM+字幕+过渡）。

## 工作流（4步）

```
Phase 1           Phase 2            Phase 3          Phase 4
音频预处理  →  构建合成文件  →  自检+Lint  →  渲染+验证
```

## 按需文件索引

| 需要时 | 读取 |
|--------|------|
| 合成规则（场景时间/字幕/BGM/过渡/特效） | `references/composition-rules.md` |
| 8种GSAP过渡模式（选模式不重写代码） | `references/transition-patterns.md` |
| 渲染前自检+Lint+验证流程 | `references/pre-render-checklist.md` |
| 遇到渲染问题 | `references/common-issues.md` |

## 执行脚本

| 步骤 | 脚本 |
|------|------|
| Phase 1: 音频预处理 | `bash scripts/prepare-audio.sh <tts> <bgm_dir> <out>` |
| Phase 2: 自动填充模板 | `python ../news-to-video/scripts/fill_composition.py <项目目录>` |
| Phase 2: 手动补全场景 | 在生成的 index.html 中填充 `{{SCENE_HTML}}` 和 `{{ENTRY_ANIMATIONS}}` |
| Phase 3: 渲染前预检 | `bash scripts/preflight-check.sh composition/` |
| Phase 4: 渲染 | `npx hyperframes render composition/ --output video.mp4` |
| Phase 4: 验证 | `bash scripts/video-verify.sh video.mp4` |

## 构建合成文件指导

1. 运行 `python ../news-to-video/scripts/fill_composition.py <项目目录>` 自动填充模板
2. 脚本自动生成：T变量、caps数组、6种过渡、BGM标签、26条字幕div
3. 手动在生成的 `composition/index.html` 中替换 `{{SCENE_HTML}}` 和 `{{ENTRY_ANIMATIONS}}`
4. 场景HTML从 `slides/index.html` 复制视觉内容
5. 入场动画可参考 `references/transition-patterns.md` 中的 easing 模式

## 关键规则

1. 字幕文本来自 TTS 脚本，不是幻灯片
2. 场景时间 = timing_reference.md 锚点，不用静音检测
3. BGM 实体复制（非 symlink），音量 0.30-0.35
4. 每场景间有过渡 + visibility:hidden kill
5. Lint 0 错误才能渲染
6. 渲染后运行 video-verify.sh 验证
