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

将热点新闻通过 PPT 营销框架转化为结构化视频内容。完整链路：选题 → 框架 → 文案 → 幻灯片 → 视频。

## 工作流总览

```
阶段1          阶段2        阶段3        阶段4         阶段5          阶段6
获取新闻  →  选题判断  →  框架选型  →  文案生成  →  PPT创建  →  视频创作
smart-search   选题清单    决策树       Prompt模板   frontend-slides  hyperframes
                            PAS/SCR    自检清单     演讲备注         ppt-to-video
                            VVV/红杉                BGM下载         字幕+TTS+BGM
```

每个阶段有明确的自检清单，不通过不进入下一阶段。

---

## 阶段1：获取新闻

### 调用
使用 `smart-search` 技能获取当前热点新闻。

### 数据源
- **36氪热榜**（科技/商业）— P0选题主要来源
- **微博热搜**（社会/综合）— P1/P2选题补充

### 输出格式
整理为 `news_source.md`，包含：
```markdown
# 新闻源数据 — YYYY-MM-DD

## 36氪热榜（科技/商业）
| rank | title | url |

## 微博热搜（社会/综合）
| rank | word | category | url |

## 选定文章全文
**标题**：...
**URL**：...
**正文要点**：...
```

### 自检
- [ ] 至少收集15条候选新闻（36氪10+条 + 微博5+条）
- [ ] 选定1篇文章并获取全文内容
- [ ] 提取5-8个正文要点（数据+观点）

---

## 阶段2：选题判断

### 选题清单

| 优先级 | 类型 | 特征 | 示例 |
|--------|------|------|------|
| **P0 优先** | 行业趋势/政策解读 | 有数据、有争议、可结构化分析 | AI融资潮、芯片政策 |
| **P0 优先** | 商业/科技争议 | 有对立观点、有商业逻辑可拆解 | 算力军备竞赛 |
| **P1 可做** | 社会热点/公共事件 | 可结构化但需更轻风格 | 消费趋势、教育改革 |
| **P1 可做** | 数据新闻/调查报告 | 天然适合PPT图表化 | 市场报告、统计数据 |
| **P2 谨慎** | 娱乐/文化现象 | 需更轻的风格，PPT感可能过重 | 综艺收视、文化趋势 |
| **避免** | 突发灾难/悲剧 | PPT感太精致会显得冷漠 | 自然灾害、事故 |

### 核心观点提炼
用一句话表达对这则新闻的看法。要求：
- 是结论句，不是主题词
- 有态度，不模棱两可
- 3秒内让人产生"为什么？"的好奇

**示例**：
- ❌ "AI行业融资分析"（主题词，无态度）
- ✅ "AI行业用万亿算力军备竞赛制造繁荣，却没人认真回答"谁来付钱""（结论+悬念）

### 自检
- [ ] 选题符合P0/P1标准
- [ ] 核心观点是一句话结论句
- [ ] 封面标题3秒测试通过（让人想看下去）
- [ ] 有至少3个可查证的数据点支撑观点

---

## 阶段3：框架选型

### 决策树

```
新闻类型是什么？
├─ 行业乱象/社会议题/用户痛点 → PAS框架
├─ 新政策/行业趋势/技术变革 → SCR框架（麦肯锡）
├─ 辟谣/反常识数据/被忽视的真相 → VVV框架（认知重塑）
└─ 创业机会/商业决策/投资判断 → 红杉精简版
```

### 框架速查卡

#### PAS（痛点-放大-方案）— 6-9页
```
P1 封面：爆炸性标题（结论即标题）
P2 Problem：痛点数据冲击
P3 Agitate：不解决会怎样（放大焦虑）
P4 Solve：三条出路/方案
P5 Evidence：历史/数据验证
P6 CTA：行动号召+评论引导
（可扩展：军备竞赛全景/单位经济学分析/反方观点）
```

#### SCR（麦肯锡）— 6页
```
P1 封面：结论先行（Action Title）
P2 Situation：现状描述
P3 Complication：核心矛盾
P4 Resolution：解决方案
P5 Evidence：案例/数据
P6 CTA：行动建议
```

#### VVV（认知重塑）— 6页
```
P1 封面：推翻常识的新观点
P2 V1 你以为的：大众认知
P3 V2 实际上的：真实数据
P4 V3 深层原因：为什么被忽视
P5 Evidence：权威背书
P6 CTA：重新思考
```

#### 红杉精简版 — 6页
```
P1 封面：方向判断
P2 赛道：市场机会
P3 痛点：用户需求
P4 方案：产品逻辑
P5 数据：增长验证
P6 CTA：投资/行动建议
```

### 框架轮换策略
3-4套框架轮换使用，避免观众产生套路疲劳。连续3期不重复同一框架。

### 自检
- [ ] 决策树判断有明确理由
- [ ] 确认逐页结构（每页标题是结论句）
- [ ] 与上期框架不同（轮换策略）

---

## 阶段4：文案生成

### 生成方法
直接用 Claude 生成逐页文案，不使用外部Prompt模板。

### 文案格式
每页包含：
```markdown
## Page N · 页面类型

**标题**：结论句（不是主题词）

**正文**：≤2句 或 3个要点

**视觉建议**：配色/构图/重点元素
```

### 文案规则
- 封面标题要"狠"，3秒内决定观众是否继续看
- 每页只有一个观点
- 标题是完整的结论句，看完标题就知道这页要说什么
- 数据必须有来源（从新闻原文提取）
- 最后一页必须有明确的CTA评论引导（"你怎么看？评论区聊聊"）
- 正文不超过2句或3个要点，给视觉留空间

### 可选：扩展补充页
6页基础框架可扩展至8-9页，补充：
- 数据全景对比（如军备竞赛各方数据）
- 经济学/逻辑分析（如单位经济学陷阱）
- 反方观点+反驳（增强论证完整性）

### 自检清单

| # | 检查项 | 标准 |
|---|--------|------|
| 1 | 封面标题吸引力 | 3秒测试：看完标题想继续看吗？ |
| 2 | 每页单一观点 | 每页只说一件事 |
| 3 | 标题都是结论句 | 不是"AI行业现状"而是"AI行业正在..." |
| 4 | 数据有来源 | 每个数字可追溯到新闻原文 |
| 5 | CTA引导评论 | 最后一页有"你怎么看？评论区聊聊" |
| 6 | 正文简洁 | ≤2句或3要点，不堆砌 |
| 7 | 视觉建议具体 | 有配色/构图/重点描述 |

全部通过 → 进入阶段5。

---

## 阶段5：PPT创建

### 5.1 生成HTML幻灯片
调用 `frontend-slides` 技能，将文案转为动画HTML幻灯片。

**配色方案**（根据新闻类型选择）：

| 新闻类型 | 配色 | 风格 |
|---------|------|------|
| 科技/商业分析 | 深蓝+金色 | 专业、理性、数据感 |
| 社会议题 | 暖灰+深红重点 | 有温度、有态度 |
| 政策解读 | 白底+深青 | 清晰、权威 |
| 辟谣/事实核查 | 红绿对比 | 对比感、真相感 |
| 创业/机会判断 | 深色+霓虹重点 | 未来感、动态感 |

### 5.2 添加演讲备注
在每页 slide HTML 中添加 `@SPEAKER-NOTES` 注释块：

```html
<!--
  @SPEAKER-NOTES
  @时长: 预计停留秒数
  @TTS: 该页完整TTS朗读文案
  @BGM: 推荐BGM曲目+情绪描述
  @重点: 视觉元素出场顺序和强调方式
  @转场: 过渡到下一页的方式
-->
```

### 5.3 下载BGM
调用 `pixabay-music-download` 技能，按情绪关键词搜索并下载3-6首BGM：
- 开场冲击：dramatic epic technology
- 紧张分析：corporate tension ambient
- 节奏推进：industrial rhythmic percussion
- 反思收束：emotional dramatic

### 5.4 生成TTS文案
输出 `tts_script.md`，格式：
```markdown
[0:00-0:04]
TTS朗读文本第一段。

[0:04-0:14]
TTS朗读文本第二段。
```
总时长目标：60-90s（抖音竖版）或 2-3min（B站横版）。

### 5.5 生成TTS音频（edge-tts）

**中文视频必须使用 edge-tts**，kokoro-onnx 中文效果差且有 token 长度限制。

#### 安装
```bash
pip install edge-tts
```

#### 选语音
```bash
edge-tts --list-voices | grep zh-CN
```

推荐语音（按视频风格选择）：

| 语音 | 风格 | 适用场景 |
|------|------|---------|
| `zh-CN-YunjianNeural` | Passion | 科技/商业/激情叙事 |
| `zh-CN-YunyangNeural` | Professional | 政策解读/严肃分析 |
| `zh-CN-XiaoxiaoNeural` | Warm | 社会议题/人文关怀 |
| `zh-CN-YunxiNeural` | Lively | 轻松/娱乐/年轻向 |

#### 逐句生成

**核心原则：每句话单独生成一个MP3，不要一次性生成整段长文本。** Edge-tts 对长文本会自动加速，导致字幕难以对齐。

将 tts_script.md 中的文本按句子拆分，每句一个mp3：
```bash
edge-tts --voice "zh-CN-YunjianNeural" --text "第一句话。" --write-media "e01.mp3"
edge-tts --voice "zh-CN-YunjianNeural" --text "第二句话。" --write-media "e02.mp3"
```

可并行生成（每批4个），大幅提速。

#### 合并音频
```bash
# 记录每段时长
for f in e*.mp3; do
  d=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$f")
  printf "%s: %6.2fs\n" "$f" "$d"
done

# 用ffmpeg concat合并
for f in e01.mp3 e02.mp3 ...; do echo "file '$PWD/$f'"; done > list.txt
ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp3
```

#### 为什么不一次性生成
- 长文本会自动加速，单句生成语速更自然
- 逐句生成后每段时间戳精确可知，作为字幕锚点
- 单句文件可单独重新生成，不需重跑全部

### 自检
- [ ] HTML幻灯片每页内容不超过视口（无滚动条）
- [ ] 配色与新闻类型匹配
- [ ] 每页有演讲备注（@时长 @TTS @BGM @重点 @转场）
- [ ] BGM下载3-6首，覆盖不同情绪段
- [ ] tts_script.md 时间轴完整覆盖所有页
- [ ] TTS使用 edge-tts 逐句生成（非 kokoro-onnx）
- [ ] 每段TTS时长已记录，用于字幕锚点计算

---

## 阶段6：视频创作

### 调用
使用 `ppt-to-video` 技能（或直接使用 `hyperframes` 技能 + 本技能中的视频合成规则）。

### 关键文件准备

```
composition/
├── index.html        # HyperFrames合成文件
├── output.mp3        # TTS音频（实体文件，非symlink）
└── bgm/              # BGM文件（实体文件，非symlink）
    ├── 01_xxx.mp3
    └── ...
```

### 视频合成核心规则

以下规则来自实战踩坑，每条都有血的教训：

#### 场景时间
- 用 TTS脚本时间 × (实际音频时长/脚本目标时长) 计算
- **不要用ffmpeg静音检测**：它把句中停顿误判为场景边界

#### 字幕
- **文本必须来自TTS脚本**，不能来自PPT幻灯片文字
- **逐句锚点法**（核心方法）：每段TTS音频的确切起止时间是已知的锚点。字幕时间 = 所在句子的音频起始时间 + 该短语在句内的字符比例偏移
  ```
  // 例：e06 "这意味着什么？不再是人类写代码造AI，而是AI写代码造更强的AI。" (7.92s, 起始32.01s)
  // "这意味着什么" 占句首6/29≈20% → 32.01 + 0.3 = 32.3s
  // "不再是人类写代码造AI" 占10/29≈34% → 32.01 + 2.2 = 34.2s
  // "而是AI写代码造更强的AI" 占13/29≈45% → 32.01 + 5.2 = 37.2s
  ```
- **停留时间按文本长度**：2-5字→2s, 6-12字→2-2.8s, 13-20字→2.8-3.5s, 20+字→3.5-4s
- 关键短语独立成条（如"囤算力"，不合并到前后句）
- 每条字幕有0.25s淡入淡出，前后0.25s重叠
- **常见错误：字幕整体偏移** — 如果后半部分字幕延迟2-4秒，通常是某个句子的起始锚点算错了。回到逐句时长表，核对每句的累积起始时间

#### BGM
- 文件必须实体复制，symlink在渲染时404
- 每条BGM用不同 `data-track-index`，同轨道不能有时间重叠
- 音量0.30-0.35（TTS保持1.0）

#### 过渡
- 每两个场景之间必须有过渡（至少8种变体轮换）
- 每次过渡后加 `tl.set(visibility:"hidden")` 清理旧场景
- 场景1默认可见，场景2+初始 `opacity:0`

#### 特效
- 数据卡片用 `back.out(1.5)` 弹性入场 + 旋转
- 关键数字（GAP/300×）用独立overlay scale-pop闪烁
- 封面标题用 `back.out(1.7)` 冲击入场
- 长停留场景加面板呼吸动画（borderColor pulse）

### 视频合成自检（渲染前）

| # | 检查项 | 验证方法 |
|---|--------|---------|
| 1 | `npx hyperframes lint` 0错误 | 运行lint命令 |
| 2 | 字幕文本与tts_script.md一致 | diff对照 |
| 3 | 字幕时长≥2s，长文本3.5-4s | 检查caps数组d值 |
| 4 | BGM文件实体存在（非symlink） | `ls -la composition/bgm/` |
| 5 | 场景时间=TTS脚本×扩展因子 | 核对T变量与脚本 |
| 6 | 每场景间有过渡+visibility kill | grep "visibility.*hidden" |
| 7 | GSAP timeline注册名=root div id | 核对两处ID一致 |

### 渲染

```bash
npx hyperframes render composition/ --output ai_bill_video.mp4
```

### 输出验证

```bash
# 音频流存在
ffprobe -v quiet -show_entries stream=codec_type,channels output.mp4
# 必须输出: h264,video + aac,audio,2

# 时长正确
ffprobe -v quiet -show_entries format=duration -of csv=p=0 output.mp4

# 音量正常
ffmpeg -i output.mp4 -af "volumedetect" -f null - 2>&1 | grep mean_volume
# mean_volume 应在 -20 到 -10 dB 之间
```

### 同步检查点
观看渲染视频，验证：
- [ ] 前10s：S1字幕与TTS同步出现和消失
- [ ] ~8s："3000亿"字幕在音频提到时出现
- [ ] ~12s："囤算力"独立显示
- [ ] ~26s：S3过渡干净无闪烁
- [ ] 最后5s：CTA字幕+淡出完成

---

## 阶段7：发布准备

### 平台适配

| 平台 | 比例 | 分辨率 | 时长 | 特点 |
|------|------|--------|------|------|
| 抖音 | 9:16竖版 | 1080×1920 | 60-90s | 封面3秒冲击，快速翻页 |
| B站 | 16:9横版 | 1920×1080 | 2-5min | 核心论点展开，数据慢下来 |
| 视频号 | 16:9兼容 | 1920×1080 | 60-120s | 兼顾两者 |
| 小红书 | 9:16竖版 | 1080×1920 | 30-60s | 更短更轻 |

### 对比测试（可选）
准备B版：同一选题用普通图文风格（非PPT框架），对比互动数据验证PPT风格效果。

---

## 依赖技能

| 阶段 | 技能 | 调用方式 |
|------|------|---------|
| 1. 获取新闻 | `smart-search` | `/smart-search` 或 Skill工具 |
| 5. PPT创建 | `frontend-slides` | `/frontend-slides` 或 Skill工具 |
| 5. BGM下载 | `pixabay-music-download` | Skill工具 |
| 6. 视频创作 | `ppt-to-video` 或 `hyperframes` | Skill工具 |

## 配套规划文件

每次新选题创建以下文件（参考 `planning-with-files:plan-zh`）：
- `task_plan.md` — 阶段进度 + 决策记录
- `findings.md` — 研究发现 + 技能依赖
- `progress.md` — 会话日志 + 踩坑记录

## 框架轮换记录

记录每次使用的框架，确保不连续重复：

| 日期 | 选题 | 框架 | 页数 |
|------|------|------|------|
| | | | |

---

## 实战案例

### 案例1：AI万亿账单

- **选题**：「80%的钱流向AI，但谁来买单？」（36氪，P0）
- **框架**：PAS扩展版（9页：封面+Problem+军备竞赛全景+Agitate+单位经济学陷阱+Solve+Evidence+反方观点+CTA）
- **配色**：深蓝#050d1a + 金色#c8a44e
- **视频**：3分钟，1920×1080，73条字幕，5轨BGM，8种过渡
- **关键踩坑**：静音检测误判场景边界（改用TTS脚本×扩展因子）、字幕文本来自PPT而非TTS（改为TTS脚本原文）、BGM symlink 404（改为实体文件）

### 案例2：Anthropic万亿IPO（抖音竖版）

- **选题**：「史上最大规模IPO逼近，超越SpaceX，28年AI自我迭代，智能爆炸倒计时」（36氪，P0）
- **框架**：SCR（麦肯锡）7页（封面+Situation+Complication+Resolution+Evidence+时代拐点+CTA）
- **配色**：深蓝#050d1a + 金色#c8a44e
- **TTS**：edge-tts `zh-CN-YunjianNeural`（激情男声），逐句生成14段，总86.3s
- **视频**：86秒，1080×1920，32条字幕，4轨BGM，6次场景过渡
- **关键踩坑**：
  - kokoro-onnx 中文效果差且有 token 长度限制 → 改用 edge-tts 逐句生成
  - 字幕后半部分延迟2-4秒：场景5的"整个科技商业史找不到第二个先例"放在了58.6s，但实际所在音频段起始于54.35s → 用逐句锚点法修正
  - GSAP从cdnjs加载超时 → 不影响渲染，可忽略或改用本地文件
