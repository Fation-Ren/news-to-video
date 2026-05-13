# Changelog

## [v0.0.1] — 2026-05-13

### Added
- 初始技能集合：`news-to-video`（编排器）、`ppt-to-video`（执行器）、`pixabay-music-download`（工具）
- 7 阶段完整流水线：新闻获取 → 选题判断 → 框架选型 → 文案生成 → PPT 创建 → 视频创作 → 发布准备
- 4 套 PPT 框架：PAS、SCR（麦肯锡）、VVV（认知重塑）、红杉精简版，含轮换策略
- edge-tts 中文 TTS 逐句生成方案 + 逐句锚点字幕法
- 阶段 7 发布文案：抖音标题、标签、置顶评论、封面选帧、发布时间策略
- 一键安装脚本：macOS (`install.sh`) 和 Windows (`install.ps1`)
- 抖音竖版实战案例（Anthropic 万亿 IPO）及 B 站横版案例
- references/ 阶段参考文档（8 个）和 scripts/ 执行脚本（5 个）
- ppt-to-video 子技能：references/ 参考文档（4 个）+ scripts/ 脚本（3 个）+ composition 模板
- 5 个实战案例记录，含优化方法论（三层减法）和踩坑记录
- `examples/` 目录：完整示例（AI 能源选题的新闻源、文案、幻灯片、TTS 脚本、渲染视频）
