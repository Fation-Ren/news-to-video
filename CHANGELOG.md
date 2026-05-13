# Changelog

## [v0.0.2] — 2026-05-13

### Changed
- `news-to-video/SKILL.md` 精简为快速索引版（512行 → 66行），实现细节按阶段拆入 `references/`
- `ppt-to-video/SKILL.md` 精简为快速索引版（343行 → 59行），细则按需读取

### Added
- `news-to-video/references/`：8 个阶段参考文档（stage1-news ~ stage7-publishing + case-studies）
- `news-to-video/scripts/`：5 个执行脚本（download_bgm.py / fill_composition.py / tts-generate.sh / tts-timing.sh / video-verify.sh）
- `ppt-to-video/references/`：4 个参考文档（composition-rules / transition-patterns / pre-render-checklist / common-issues）
- `ppt-to-video/scripts/`：3 个脚本 + 1 个模板（prepare-audio.sh / preflight-check.sh / composition-template.html）
- `CHANGELOG.md`

### Changed
- `CLAUDE.md` 目录结构更新，反映新增的 `references/` 和 `scripts/` 目录

---

## [v0.0.1] — 2026-05-13

### Added
- 初始技能集合：`news-to-video`（7阶段编排器）、`ppt-to-video`（视频合成执行器）、`pixabay-music-download`（BGM下载工具）
- 4 套 PPT 框架：PAS、SCR（麦肯锡）、VVV（认知重塑）、红杉精简版，含轮换策略
- edge-tts 中文 TTS 逐句生成方案 + 逐句锚点字幕法
- 阶段 7 发布文案：抖音标题、标签、置顶评论、封面选帧、发布时间策略
- 一键安装脚本：macOS (`install.sh`) 和 Windows (`install.ps1`)
- 5 个实战案例记录，含优化方法论（三层减法）和脚本踩坑
- `examples/` 目录：完整 AI 能源选题示例（新闻源 → 文案 → 幻灯片 → TTS → 渲染视频）
