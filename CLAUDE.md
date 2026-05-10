# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Repository Overview

A Claude Code skill collection for end-to-end news commentary video production. Contains 3 skills:

| Skill | Type | Role |
|-------|------|------|
| `news-to-video` | Orchestrator | 7-stage pipeline: news → topic → framework → copy → slides → video |
| `ppt-to-video` | Executor | HTML slides + TTS + BGM → HyperFrames MP4 |
| `pixabay-music-download` | Utility | Pixabay royalty-free BGM search & download |

## Skills Architecture

```
news-to-video/                    # Orchestrator (bundled)
├── ppt-to-video/                 # Stage 6 executor (bundled)
├── pixabay-music-download/       # Stage 5 utility (bundled)
├── smart-search                  # Stage 1 (external dep)
├── frontend-slides               # Stage 5 (external dep)
├── hyperframes                   # Stage 6 render engine (external dep)
└── planning-with-files:plan-zh   # Planning (external dep)
```

## Directory Structure

```
news-to-video/
├── README.md
├── CLAUDE.md
├── LICENSE
├── news-to-video/
│   └── SKILL.md
├── ppt-to-video/
│   └── SKILL.md
├── pixabay-music-download/
│   └── SKILL.md
└── examples/
    ├── news_source.md
    ├── copy_scr_ai_energy.md
    ├── ai_energy_presentation.html
    ├── tts_script.md
    └── ai_energy_video.mp4
```

## Progressive Disclosure

1. **Metadata** (YAML frontmatter `name` + `description`) — always in context
2. **SKILL.md body** — loaded when skill triggers
3. **Sub-skills** — loaded on demand as each pipeline stage executes

## Key Design Decisions

- **Framework rotation**: 4 frameworks (PAS/SCR/VVV/Sequoia), never repeat 3 consecutive runs
- **Caption ground truth**: Always from TTS script, never from PPT slide text
- **BGM file handling**: Physical copies only, symlinks return 404 at render time
- **Scene timing**: TTS script duration × expansion factor, never ffmpeg silence detection
- **6-page base, expandable to 9**: Extra pages for data panorama, unit economics, counter-arguments

## Common Pitfalls (across all skills)

1. Captions must match TTS script verbatim — PPT slide text ≠ spoken text
2. BGM files must be physically copied to `composition/bgm/`, not symlinked
3. `npx hyperframes lint` must pass with 0 errors before rendering
4. Every scene transition needs `tl.set(visibility:"hidden")` for the old scene
5. Audio stream must be verified post-render: `ffprobe` check for aac,audio,2

## Editing SKILL.md Files

- Keep YAML frontmatter `description` current — it determines trigger matching
- Chinese trigger phrases should match real user phrasing
- Each stage's self-check checklist is the quality gate — keep exhaustive
- Framework cards should stay concise (decision tree format)

## Publishing Checklist

Before tagging a release:
- [ ] All SKILL.md frontmatter valid (name, description present)
- [ ] External dependencies documented in README
- [ ] At least one complete example run in `examples/`
- [ ] README skill table matches actual directories
