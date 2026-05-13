# 阶段6：视频创作

调用 `ppt-to-video` 技能。具体细则在 ppt-to-video 技能的子文件中：

| 需要 | 读取 |
|------|------|
| 合成规则（场景时间/字幕/BGM/过渡/特效） | `../ppt-to-video/references/composition-rules.md` |
| 8种GSAP过渡模式 | `../ppt-to-video/references/transition-patterns.md` |
| 渲染前自检+Lint+验证 | `../ppt-to-video/references/pre-render-checklist.md` |
| 渲染问题排查 | `../ppt-to-video/references/common-issues.md` |

## 执行脚本

| 步骤 | 命令 |
|------|------|
| 音频预处理 | `bash ../ppt-to-video/scripts/prepare-audio.sh tts/ bgm/ composition/` |
| 自动填充模板 | `python scripts/fill_composition.py .`（自动生成T变量+caps+过渡+BGM标签+字幕div） |
| 手动补全场景 | 在 composition/index.html 中填充 `{{SCENE_HTML}}` 和 `{{ENTRY_ANIMATIONS}}` |
| 渲染前预检 | `bash ../ppt-to-video/scripts/preflight-check.sh composition/` |
| 渲染 | `npx hyperframes render composition/ --output video.mp4` |
| 验证 | `bash ../ppt-to-video/scripts/video-verify.sh video.mp4` |

## 输入文件
```
composition/
├── index.html        # HyperFrames合成文件（从模板生成）
├── output.mp3        # TTS音频（实体文件，非symlink）
└── bgm/              # BGM文件（实体文件，非symlink）
```

## 关键规则速记
1. 字幕文本来自 TTS 脚本，不是幻灯片
2. 场景时间 = timing_reference.md 锚点，不用静音检测
3. BGM 实体复制（非 symlink），音量 0.30-0.35
4. 每场景间有过渡 + visibility:hidden kill
5. Lint 0 错误才能渲染
6. 渲染后运行 video-verify.sh
