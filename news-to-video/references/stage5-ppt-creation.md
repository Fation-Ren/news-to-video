# 阶段5：PPT创建

## 5.1 生成HTML幻灯片
调用 `frontend-slides` 技能，将文案转为动画HTML幻灯片。

### 配色方案（根据新闻类型选择）

| 新闻类型 | 配色 | 风格 |
|---------|------|------|
| 科技/商业分析 | 深蓝+金色 | 专业、理性、数据感 |
| 社会议题 | 暖灰+深红重点 | 有温度、有态度 |
| 政策解读 | 白底+深青 | 清晰、权威 |
| 辟谣/事实核查 | 红绿对比 | 对比感、真相感 |
| 创业/机会判断 | 深色+霓虹重点 | 未来感、动态感 |

## 5.2 添加演讲备注
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

## 5.3 下载BGM
使用 Python 脚本从 Pixabay 搜索并下载免版税BGM（需 Chrome 浏览器）：
```bash
python scripts/download_bgm.py "dramatic epic technology" bgm/ 1
python scripts/download_bgm.py "corporate tension ambient" bgm/ 1
python scripts/download_bgm.py "emotional dramatic" bgm/ 1
```
每次下载1首（可并行运行3次），3首下载到 `bgm/` 目录。
关键词映射：开场冲击→epic technology / 紧张分析→corporate tension / 反思收束→emotional dramatic

## 5.4 生成TTS文案
输出 `tts_script.md`，格式：
```markdown
[0:00-0:05] 第一段文本。
[0:05-0:13] 第二段文本。
```
总时长目标：60-90s（抖音竖版）或 2-3min（B站横版），30-60s（小红书）。

## 5.5 生成TTS音频（edge-tts）

中文视频必须使用 edge-tts（kokoro-onnx 中文效果差且有 token 长度限制）。

### 安装与选语音
```bash
pip install edge-tts
edge-tts --list-voices | grep zh-CN
```

| 语音 | 风格 | 适用场景 |
|------|------|---------|
| `zh-CN-YunjianNeural` | Passion | 科技/商业/激情叙事 |
| `zh-CN-YunyangNeural` | Professional | 政策解读/严肃分析 |
| `zh-CN-XiaoxiaoNeural` | Warm | 社会议题/人文关怀 |
| `zh-CN-YunxiNeural` | Lively | 轻松/娱乐/年轻向 |

### 生成策略：按页分段 vs 逐句

| 策略 | 文件数 | 精度 | 适用场景 |
|------|--------|------|---------|
| **按页分段** | 6段（每页1段） | 中（页级锚点） | 短视频（≤60s） |
| **逐句** | ~20-30句 | 高（句级锚点） | 长视频（>60s） |

核心原则：每句话/每页单独生成一个MP3，不要一次性生成整段长文本（edge-tts对长文本会自动加速）。

执行脚本：`scripts/tts-generate.sh`

## 5.6 生成TTS Timing Reference（逐句锚点表）

TTS生成完成后必须输出 `timing_reference.md`，作为字幕时间计算的唯一依据。

执行脚本：`scripts/tts-timing.sh`（记录段时长+生成锚点表+合并音频）

`timing_reference.md` 格式参见 `scripts/tts-timing.sh` 输出说明。

## 自检
- [ ] HTML幻灯片每页内容不超过视口（无滚动条）
- [ ] 配色与新闻类型匹配
- [ ] 每页有演讲备注（@时长 @TTS @BGM @重点 @转场）
- [ ] BGM下载3-6首，覆盖不同情绪段
- [ ] tts_script.md 时间轴完整覆盖所有页
- [ ] TTS使用 edge-tts 逐句或按页生成（非 kokoro-onnx）
- [ ] 每段TTS时长已记录
- [ ] timing_reference.md 锚点表已生成，包含逐段锚点和逐句字幕拆分
