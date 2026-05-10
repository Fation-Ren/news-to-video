# News-to-Video: 端到端新闻评论视频生产线

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-2.0.13+-purple.svg)](https://claude.com/code)

将热点新闻通过 **PPT 营销框架** 转化为结构化视频内容。从选题到渲染发布，一条命令走完全流程。

```
选题 → 框架选型 → 文案生成 → PPT幻灯片 → 视频合成 → 发布
```

---

## 仓库包含 3 个技能

| 技能 | 类型 | 用途 |
|------|------|------|
| [`news-to-video`](news-to-video/SKILL.md) | 顶层编排器 | 全流程 7 阶段编排，从选题到成品视频 |
| [`ppt-to-video`](ppt-to-video/SKILL.md) | 阶段执行器 | HTML 幻灯片 + TTS + BGM → HyperFrames 视频合成 |
| [`pixabay-music-download`](pixabay-music-download/SKILL.md) | 工具技能 | Pixabay 免版税 BGM 搜索与下载 |

---

## 快速开始

在 Claude Code 中输入：

```
做一期视频
```

`news-to-video` 会自动激活，引导你完成 7 个阶段的全流程编排。

---

## 安装

将 3 个技能目录复制到 Claude Code skills 路径：

```bash
cp -r news-to-video ~/.claude/skills/news-to-video
cp -r ppt-to-video ~/.claude/skills/ppt-to-video
cp -r pixabay-music-download ~/.claude/skills/pixabay-music-download
```

### 外部依赖

以下技能需要单独安装：

| 技能 | 用途 |
|------|------|
| `smart-search` | 36氪热榜 + 微博热搜采集 |
| `frontend-slides` | 动画 HTML 幻灯片生成 |
| `hyperframes` | HTML 视频渲染引擎（含 CLI） |
| `planning-with-files:plan-zh` | 三文件规划管理 |

### 环境要求

```bash
npx hyperframes --version   # HyperFrames CLI
ffmpeg -version             # 音频处理 + 视频验证
```

---

## 工作流

```
阶段1          阶段2        阶段3        阶段4         阶段5          阶段6
获取新闻  →  选题判断  →  框架选型  →  文案生成  →  PPT创建  →  视频创作
smart-search   选题清单    决策树       Prompt模板   frontend-slides  hyperframes
                            PAS/SCR    自检清单     演讲备注         ppt-to-video
                            VVV/红杉                BGM下载         字幕+TTS+BGM
```

每个阶段有明确的自检清单，不通过不进入下一阶段。

---

## 4 套 PPT 框架

根据新闻类型自动选择，3-4 套轮换避免套路疲劳。

### PAS（痛点-放大-方案）— 6-9页
适合：行业乱象、社会议题、用户痛点

```
P1 封面  → 爆炸性标题（结论即标题）
P2 Problem → 痛点数据冲击
P3 Agitate → 不解决会怎样
P4 Solve   → 三条出路/方案
P5 Evidence → 历史/数据验证
P6 CTA     → 行动号召+评论引导
```

### SCR 麦肯锡 — 6页
适合：新政策、行业趋势、技术变革

```
P1 封面          → 结论先行
P2 Situation     → 现状描述
P3 Complication  → 核心矛盾
P4 Resolution    → 解决方案
P5 Evidence      → 案例/数据
P6 CTA           → 行动建议
```

### VVV 认知重塑 — 6页
适合：辟谣、反常识数据、被忽视的真相

```
P1 封面      → 推翻常识的新观点
P2 V1 你以为的 → 大众认知
P3 V2 实际上的 → 真实数据
P4 V3 深层原因 → 为什么被忽视
P5 Evidence  → 权威背书
P6 CTA       → 重新思考
```

### 红杉精简版 — 6页
适合：创业机会、商业决策、投资判断

```
P1 封面  → 方向判断
P2 赛道  → 市场机会
P3 痛点  → 用户需求
P4 方案  → 产品逻辑
P5 数据  → 增长验证
P6 CTA   → 投资/行动建议
```

---

## 配色方案

| 新闻类型 | 配色 | 风格 |
|---------|------|------|
| 科技/商业分析 | 深蓝+金色 | 专业、理性、数据感 |
| 社会议题 | 暖灰+深红重点 | 有温度、有态度 |
| 政策解读 | 白底+深青 | 清晰、权威 |
| 辟谣/事实核查 | 红绿对比 | 对比感、真相感 |
| 创业/机会判断 | 深色+霓虹重点 | 未来感、动态感 |

---

## 平台适配

| 平台 | 比例 | 分辨率 | 时长 |
|------|------|--------|------|
| 抖音 | 9:16 竖版 | 1080×1920 | 60-90s |
| B站 | 16:9 横版 | 1920×1080 | 2-5min |
| 视频号 | 16:9 兼容 | 1920×1080 | 60-120s |
| 小红书 | 9:16 竖版 | 1080×1920 | 30-60s |

---

## 实战案例

### 「AI竞争的下半场，拼的不是显卡，是电厂」

- **选题**：算电协同政策解读（36氪，P0）
- **框架**：SCR 麦肯锡 6页
- **配色**：深蓝 #0a1628 + 金 #c8a44e
- **视频**：1920×1080，多轨BGM，动画字幕，场景过渡
- 完整示例文件见 [`examples/`](examples/) 目录：
  - `news_source.md` — 新闻源采集
  - `copy_scr_ai_energy.md` — SCR 框架文案
  - `ai_energy_presentation.html` — HTML 幻灯片
  - `tts_script.md` — TTS 配音脚本
  - `ai_energy_video.mp4` — 最终渲染成品

---

## 血的教训（渲染前必查）

| # | 问题 | 正确做法 |
|---|------|---------|
| 1 | 字幕文本来自PPT而非TTS | 字幕必须与 TTS 脚本逐字对照 |
| 2 | BGM 用 symlink 渲染404 | 实体复制到 `composition/bgm/` |
| 3 | 场景时间用静音检测 | 用 TTS脚本时间 × 扩展因子 |
| 4 | 字幕统一时长 | 按文本长度分档：2-5字→2s, 20+字→3.5-4s |
| 5 | 场景间无过渡 | 每两个场景间必须有过渡+visibility kill |
| 6 | 不跑 lint 直接渲染 | `npx hyperframes lint` 0错误才能渲染 |
| 7 | 音频流缺失 | 渲染后 ffprobe 确认 aac,audio,2 流存在 |

---

## 文件结构（单期示例）

```
ppt_video/
├── news_source.md              # 新闻源数据
├── copy_pas_ai_bill.md         # 文案（9页）
├── tts_script.md               # TTS 配音时间轴
├── ai_bill_presentation.html   # HTML 幻灯片（含演讲备注）
├── bgm/                        # BGM 素材（3-6首）
├── output.mp3                  # TTS 音频
├── composition/
│   ├── index.html              # HyperFrames 合成源文件
│   ├── output.mp3              # TTS 实体复制
│   └── bgm/                    # BGM 实体复制
└── ai_bill_video.mp4           # 最终渲染视频
```

---

## License

MIT © 2026
