---
name: news-to-video
description: |
  End-to-end pipeline: news gathering → topic selection → PPT framework → copywriting → HTML slides → video with TTS+BGM+captions.
  Use this skill whenever the user wants to turn news/current events into video content, create news commentary videos,
  produce PPT-style video from articles, or run the full content production workflow. Also triggers on: "做一期视频",
  "新闻评论视频", "PPT转视频全流程", "从选题到视频", "热点新闻做视频", "AI PPT video pipeline".
  This is the TOP-LEVEL orchestrator — it coordinates smart-search, frontend-slides, hyperframes, ppt-to-video, and pixabay-music-download.
---

# News-to-Video: 端到端新闻评论视频生产线

将热点新闻通过 PPT 营销框架转化为结构化视频内容。7个阶段，每阶段有自检清单。

```
阶段1          阶段2        阶段3        阶段4         阶段5          阶段6        阶段7
获取新闻  →  选题判断  →  框架选型  →  文案生成  →  PPT创建  →  视频创作  →  发布准备
```

## 各阶段快速索引

| 阶段 | 内容 | 详细文档 | 执行脚本 |
|------|------|---------|---------|
| 1 | 获取新闻（36氪/微博） | `references/stage1-news.md` | — |
| 2 | 选题判断（P0/P1/P2） | `references/stage2-topic.md` | — |
| 3 | 框架选型（PAS/SCR/VVV/红杉） | `references/stage3-framework.md` | — |
| 4 | 文案生成（6-9页） | `references/stage4-copywriting.md` | — |
| 5 | PPT创建（幻灯片+TTS+BGM） | `references/stage5-ppt-creation.md` | `scripts/download_bgm.py` / `scripts/tts-generate.sh` |
| 6 | 视频创作（合成+渲染+验证） | `references/stage6-video-composition.md` | `scripts/fill_composition.py` / `scripts/tts-timing.sh` |
| 7 | 发布准备（平台适配+文案） | `references/stage7-publishing.md` | — |
| — | 实战案例 | `references/case-studies.md` | — |

## 依赖技能

| 阶段 | 技能 |
|------|------|
| 1. 获取新闻 | `smart-search` |
| 5. PPT创建 | `frontend-slides` |
| 5. BGM下载 | `pixabay-music-download` |
| 6. 视频创作 | `ppt-to-video` 或 `hyperframes` |

## 配套规划文件

每次新选题创建：
- `task_plan.md` — 阶段进度 + 决策记录 + Token消耗
- `findings.md` — 研究发现 + 技能依赖
- `progress.md` — 会话日志 + 踩坑记录
- `timing_reference.md` — TTS逐句锚点表（阶段5.6产出，阶段6输入）

## 框架轮换记录

| 日期 | 选题 | 框架 | 页数 |
|------|------|------|------|
| | | | |

## 关键规则速记

1. **每页一个观点**，标题是结论句不是主题词
2. **TTS必须edge-tts逐句/按页生成**，不一次性生成长文本
3. **字幕文本来自TTS脚本**，不是PPT幻灯片
4. **场景时间=timing_reference.md锚点**，不用静音检测
5. **BGM实体复制**，不symlink；音量0.30-0.35
6. **每场景间有过渡+visibility:hidden kill**
7. **lint 0错误**才能渲染
8. **脚本优先**：同一操作出现2次以上 → 写脚本；把信息从上下文推到执行层 | 详见 `references/case-studies.md`
