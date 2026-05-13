# HyperFrames 合成规则

## 输入文件

| 文件 | 用途 |
|------|------|
| `composition/output.mp3` | TTS音频（实体文件，非symlink） |
| `composition/bgm/*.mp3` | BGM文件（实体文件，非symlink） |
| `timing_reference.md` | 场景时间+字幕锚点 |
| `tts_script.md` | 字幕文本来源 |
| `slides/index.html` | 场景视觉设计参考 |

## 场景时间

- 优先使用 `timing_reference.md` 中的逐段锚点（精确）
- 仅无锚点表时才用扩展因子：`TTS脚本时间 × (实际音频时长/脚本目标时长)`
- **不用ffmpeg静音检测**：它把句中停顿误判为场景边界

## 字幕规则

### 内容：与TTS完全一致
字幕文本只能包含TTS脚本中实际朗读的内容。幻灯片文字 ≠ 字幕文字。

### 时长：按文本长度
| 字数 | 显示时长 |
|------|---------|
| 2-5字 | 2.0s（最短） |
| 6-12字 | 2.0-2.8s |
| 13-20字 | 2.8-3.5s |
| 20+字 | 3.5-4.0s |

不用统一时长。

### 时间：逐句锚点法
字幕时间 = 所在句子的音频起始时间 + 该短语在句内的字符比例偏移。

每条字幕0.25s淡入淡出，前后0.25s重叠。关键短语独立成条。

### 渲染代码
```js
caps.forEach(function(c, i) {
  tl.fromTo("#cap"+i, { opacity:0, y:16 }, { opacity:1, y:0, duration:0.25, ease:"power2.out" }, c.t);
  tl.to("#cap"+i, { opacity:0, duration:0.25, ease:"power2.in" }, c.t + c.d - 0.25);
  tl.set("#cap"+i, { opacity:0, visibility:"hidden" }, c.t + c.d + 0.05);
});
```

## BGM

- 文件必须实体复制，symlink渲染时404
- 每条BGM用不同 `data-track-index`，同轨道不能有时间重叠
- 音量 `data-volume="0.30-0.35"`（TTS保持1.0）

```html
<audio id="bgm1" data-start="0" data-duration="30" data-track-index="1"
  src="bgm/01_epic_opening.mp3" data-volume="0.35"></audio>
```

## 过渡

- 每两个场景之间必须有过渡
- 过渡后加 `tl.set(visibility:"hidden")` 清理旧场景
- 场景1默认可见，场景2+初始 `opacity:0`
- 8种过渡模式见 `references/transition-patterns.md`

## 特效

- 数据卡片：`back.out(1.5)` 弹性入场
- 关键数字：独立overlay scale-pop闪烁
- 封面标题：`back.out(1.7)` 冲击入场
- 长停留场景：面板呼吸动画

## 设计系统

匹配原始幻灯片的配色和字体。中文字体用 Noto Sans SC，标题58-88px，正文26-28px，视频尺寸按平台（1080×1920竖版 或 1920×1080横版）。
