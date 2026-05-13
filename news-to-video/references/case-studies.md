# 实战案例

## 案例1：AI万亿账单
- **选题**：「80%的钱流向AI，但谁来买单？」（36氪，P0）
- **框架**：PAS扩展版（9页：封面+Problem+军备竞赛全景+Agitate+单位经济学陷阱+Solve+Evidence+反方观点+CTA）
- **配色**：深蓝#050d1a + 金色#c8a44e
- **视频**：3分钟，1920×1080，73条字幕，5轨BGM，8种过渡
- **关键踩坑**：静音检测误判场景边界（改用TTS脚本×扩展因子）、字幕文本来自PPT而非TTS（改为TTS脚本原文）、BGM symlink 404（改为实体文件）

## 案例2：Anthropic万亿IPO（抖音竖版）
- **选题**：「史上最大规模IPO逼近，超越SpaceX，28年AI自我迭代，智能爆炸倒计时」
- **框架**：SCR（麦肯锡）7页（封面+Situation+Complication+Resolution+Evidence+时代拐点+CTA）
- **配色**：深蓝#050d1a + 金色#c8a44e
- **TTS**：edge-tts `zh-CN-YunjianNeural`，逐句生成14段，总86.3s
- **视频**：86秒，1080×1920，32条字幕，4轨BGM，6次场景过渡
- **关键踩坑**：
  - kokoro-onnx 中文效果差且有 token 长度限制 → 改用 edge-tts 逐句生成
  - 字幕后半部分延迟2-4秒 → 用逐句锚点法修正
  - GSAP从cdnjs加载超时 → 不影响渲染，可忽略

## 案例3：AI正在吃掉你的每一个App（小红书竖版）
- **选题**：「快手拆可灵融20亿、网易云接DeepSeek、淘宝上线AI购物」
- **框架**：PAS（6页精简版）
- **配色**：深蓝#050d1a + 金色#c8a44e
- **TTS**：edge-tts `zh-CN-YunjianNeural`，按页分段6段，总67.25s
- **视频**：67秒，1080×1920，22条字幕，3轨BGM，5次场景过渡
- **新增产出**：`timing_reference.md` 逐句锚点表（场景时间直接用锚点，无需扩展因子）

## 案例4：390万的载人机甲（抖音竖版）
- **选题**：「宇树发布载人变形机甲，定价390万起」
- **框架**：SCR（麦肯锡）7页 — 轮换序列：PAS→SCR
- **配色**：深色#060d16 + 霓虹蓝#00d4ff
- **TTS**：edge-tts `zh-CN-YunjianNeural`，按页分段7段，总93s
- **视频**：93秒，1080×1920，26条字幕，3轨赛博朋克BGM，6次场景过渡
- **优化点**：skill拆分后首次实战，系统加载 -90%

## 案例5：量子计算走出科幻片（B站横版）
- **选题**：「波色量子在肿瘤、脑机等领域交出百余个落地案例」
- **框架**：VVV（认知重塑）8页 — 轮换序列：PAS→SCR→VVV
- **配色**：深色#030712 + 量子紫#7c3aed + 量子青#06b6d4
- **TTS**：edge-tts `zh-CN-YunjianNeural`，按页分段8段，总128s
- **视频**：128秒，1920×1080，38条字幕，3轨BGM，7次场景过渡
- **优化点**：Python脚本接管BGM下载和合成填充，token降至优化前的35%

---

## 优化方法论：三层减法

三期视频 token 递减趋势：66,500 → 30,500 → 23,300。

核心原则：**把信息从上下文层推到执行层**。Agent 的上下文是有限且昂贵的资源，任何重复性工作都应该脚本化。

| 层 | 做法 | 原理 |
|----|------|------|
| 结构层 | 技能主文件 578→64行，实现细节按阶段拆入 references/ | Agent 按需读取，不预加载不必要的信息 |
| 模板层 | composition/index.html 从全手写 → 占位符模板 | 固定结构复用，只填充变化部分 |
| 脚本层 | BGM下载/合成填充从 Agent 手工 → Python 脚本 | 完全不占上下文，执行速度也更快 |

判断标准：某操作出现超过两次，就写脚本。

## 脚本踩坑记录

### CSS `+` 转义
`document.querySelectorAll('script[type=application/ld+json]')` 非法。`+` 在 CSS 选择器中是相邻兄弟组合器，需用 `\\+` 转义或用 `[type]` + `.indexOf("ld+json")` 过滤。

### subprocess 引号链
Python → shell → opencli → JavaScript 四层嵌套，每层都有自己的引号规则。最终稳定方案：`shell=True`，JS 内部统一用双引号，shell 层用单引号包裹整个 JS 字符串。

### `{from}` 占位符陷阱
Python `str.format(from_=x)` 不能匹配模板中的 `{from}`，因为 `from` 是 import 关键字。模板占位符命名要避开语言关键字，用 `{frm}` `{tgt}` 替代。

### URL 路径重复
Pixabay 搜索结果 href 已是 `/music/...`，又拼接了 `PIXABAY_MUSIC = ".../music"` → `/music/music/`。调试时 opencli 只返回 JSON 对象而非浏览器地址栏，不易察觉。
