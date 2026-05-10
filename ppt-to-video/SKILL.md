---
name: ppt-to-video
description: |
  Convert PPT HTML slides + TTS audio + BGM into a HyperFrames video composition.
  Use this skill whenever the user wants to: create a video from presentation slides,
  synthesize slides with voiceover into MP4, add captions synced to TTS audio,
  convert PPT HTML to video with background music, or produce narrated video content
  from existing HTML presentations. Triggers on: "合成视频", "生成视频", "slides to video",
  "PPT转视频", "add voiceover to slides", "make video from HTML", "render slides as video".
---

# PPT-to-Video: HTML Slides → HyperFrames Video

Convert a set of HTML presentation slides into a rendered MP4 video with TTS narration, background music, animated captions, and scene transitions.

---

## Required Input Files

Before starting, verify all of these exist:

| File | Format | Purpose |
|------|--------|---------|
| HTML presentation | `.html` with `.slide` elements | Visual source (9 slides typical) |
| TTS audio | `.mp3` or `.wav` (mono, 44100Hz) | Voice narration for full duration |
| TTS script | `.md` with `[start-end] text` lines | Ground truth for caption content |
| BGM tracks | `.mp3` (3-6 files in `bgm/` dir) | Background music for different moods |
| Speaker notes | HTML comments in slides with `@BGM`, `@时长`, `@重点` | Scene timing hints, BGM cues, emphasis |

### TTS Script Format

The TTS script is the single source of truth for captions. **Never use slide text for captions** — only use what's actually spoken in the TTS audio.

```markdown
[0:00-0:04]
全球80%的风投资金砸向AI，但这笔万亿账单，根本没人买单。

[0:04-0:14]
2026年第一季度，3000亿美元风投，其中2400亿只干了一件事——囤算力。
```

---

## Phase 1: Audio Preprocessing

### 1.1 Convert TTS Audio if Needed

```bash
# Check format
ffprobe -v quiet -show_entries stream=codec_name,channels,sample_rate /path/to/audio

# Convert TS/other to MP3
ffmpeg -i input.ts -c:a libmp3lame -b:a 192k output.mp3

# Verify duration
ffprobe -v quiet -show_entries format=duration -of csv=p=0 output.mp3
```

### 1.2 Calculate Audio Expansion Factor

The TTS script was written for a target duration (e.g., 90s). The actual audio is usually longer (e.g., 180s). Calculate the ratio:

```
expansion_factor = actual_audio_duration / script_target_duration
```

All scene timing from the script is multiplied by this factor.

### 1.3 Prepare BGM Files

```bash
# Create composition directory
mkdir -p composition/bgm

# Copy files (NOT symlinks — hyperframes render needs real files)
cp output.mp3 composition/
cp bgm/*.mp3 composition/bgm/
```

### 1.4 Detect Audio Timing (Optional but Recommended)

```bash
ffmpeg -i output.mp3 -af "silencedetect=noise=-30dB:d=0.5" -f null - 2>&1 | \
  grep "silence_start\|silence_end"
```

**WARNING**: Silence detection identifies sentence pauses, NOT scene boundaries. Do not use it for scene timing. Use TTS script × expansion factor instead. Silence detection is only useful as a secondary check.

---

## Phase 2: Build HyperFrames Composition

### 2.1 Scene Timing

Calculate scene boundaries from the TTS script timing, multiplied by the expansion factor:

| Scene | Script Time | × Factor | Actual Time |
|-------|-------------|----------|-------------|
| S1 Cover | 0:00-0:04 | ×2 | 0-8s |
| S2 Problem | 0:04-0:14 | ×2 | 8-28s |
| ... | ... | ... | ... |

Use these in the GSAP timeline:
```js
var T = { s1:0, s2:8, s3:28, s4:52, s5:72, s6:96, s7:116, s8:136, s9:164, end:180 };
```

### 2.2 Scene Transitions (Non-Negotiable)

Every multi-scene composition must have transitions between ALL scenes. Vary the transition type:

```js
// S1→S2: slam zoom
tl.to("#s1", { scale:1.06, opacity:0, duration:0.4, ease:"power3.in" }, T.s2);
tl.fromTo("#s2", { scale:0.93, opacity:0 }, { scale:1, opacity:1, duration:0.55, ease:"back.out(1.4)" }, T.s2);
tl.set("#s1", { visibility:"hidden" }, T.s2+0.45);

// S2→S3: whip pan
tl.to("#s2", { x:-100, opacity:0, duration:0.4, ease:"power3.in" }, T.s3);
tl.fromTo("#s3", { x:100, opacity:0 }, { x:0, opacity:1, duration:0.55, ease:"power3.out" }, T.s3);
tl.set("#s2", { visibility:"hidden" }, T.s3+0.45);
```

**Always add** `visibility: hidden` after each scene exits. Scene 1 is visible by default; scenes 2+ start with `opacity: 0`.

### 2.3 BGM Audio Tracks

Put each BGM on a separate `data-track-index`. Volume at 0.30-0.35 (TTS stays at 1.0):

```html
<audio id="bgm1" data-start="0" data-duration="30" data-track-index="1"
  src="bgm/03_technology_dramatic.mp3" data-volume="0.35"></audio>
<audio id="bgm2" data-start="28" data-duration="50" data-track-index="2"
  src="bgm/01_corporate_tension.mp3" data-volume="0.32"></audio>
```

BGM tracks on the same track index MUST NOT overlap in time. Use separate track indices when crossfading.

### 2.4 Caption Rules

**The most error-prone part.** These rules are derived from repeated testing:

#### Content: Match TTS Exactly

Captions must contain ONLY text that appears in the TTS script. Slide subtitle text (like "钱在烧，算力在堆") is often NOT in the TTS audio — do not caption it.

```js
// WRONG — this text is from the slide, not the TTS
{ t:6.5, text:'钱在烧，算力在堆，用户在大方地用' }

// CORRECT — only text actually spoken
{ t:0.8, text:'全球80%的风投资金砸向AI' }
```

#### Duration: Based on Text Length

All captions follow this formula:

| Character count | Display duration |
|-----------------|-----------------|
| 2-5 chars | 2.0s (minimum) |
| 6-12 chars | 2.0-2.8s |
| 13-20 chars | 2.8-3.5s |
| 20+ chars | 3.5-4.0s |

**Never use uniform 2.5s for all captions.** Short captions disappear too slowly, long captions disappear too fast.

#### Timing: Within Scene Boundaries

Space captions so the total fits within the scene duration. Captions at the end of a scene extend to fill remaining time. Use 0.25s fade-in and 0.25s fade-out with overlap:

```js
caps.forEach(function(c, i) {
  tl.fromTo("#cap"+i, { opacity:0, y:10 }, { opacity:1, y:0, duration:0.25, ease:"power2.out" }, c.t);
  tl.to("#cap"+i, { opacity:0, duration:0.25, ease:"power2.in" }, c.t + c.d - 0.25);
  tl.set("#cap"+i, { opacity:0, visibility:"hidden" }, c.t + c.d + 0.05);
});
```

#### Split Key Phrases

Impactful short phrases should be standalone captions, not merged with adjacent text:

```js
// WRONG — merged
{ t:10.2, text:'其中2400亿只干了一件事——囤算力' }

// CORRECT — split for impact
{ t:10.3, text:'其中2400亿只干了一件事' },
{ t:12.0, text:'囤算力' },
```

### 2.5 Design System

Match the original presentation's design. Use distinctive fonts (Noto Serif SC + Noto Sans SC for Chinese), video-appropriate sizes (headlines 58-88px, body 26-28px), and the presentation's color palette.

---

## Phase 3: Self-Check Before Render

### Lint Check (MUST pass with 0 errors)

```bash
npx hyperframes lint composition/
```

Fix every `✗` error before rendering. Common errors:
- `overlapping_clips_same_track`: BGM tracks overlap → use different track indices
- `invalid_inline_script_syntax`: JS syntax error → check with `node --check`
- `scene_layer_missing_visibility_kill`: Missing `tl.set(visibility:"hidden")` after exit

### Validate

```bash
npx hyperframes validate composition/
```

### Pre-Render Checklist

| # | Check | How to verify |
|---|-------|---------------|
| 1 | All audio files are real copies (not symlinks) | `ls -la composition/bgm/` |
| 2 | TTS audio path is `src="output.mp3"` (in composition dir) | Check `<audio id="tts">` |
| 3 | BGM tracks on different `data-track-index` values | Count unique track indices |
| 4 | No BGM tracks overlap on same track index | Verify start/duration doesn't overlap |
| 5 | Captions match TTS script text exactly | Diff captions against tts_script.md |
| 6 | Caption durations follow text-length rules | Check min ≥ 2.0s |
| 7 | Each scene boundary has a GSAP transition | Count transitions (should be 8 for 9 scenes) |
| 8 | Each transition has a `visibility:hidden` kill | Grep for `visibility:"hidden"` |
| 9 | Scene 1 visible by default, scenes 2+ `opacity:0` | Check scene div style attributes |
| 10 | GSAP timeline registered as `window.__timelines["id"]` | Match composition-id in root div |

---

## Phase 4: Render

```bash
npx hyperframes render composition/ --output output.mp4
```

The render takes ~70s for a 3-minute 1920×1080 30fps video on 12 cores.

---

## Phase 5: Output Verification

### Audio Check

```bash
ffprobe -v quiet -show_entries stream=codec_type,channels,codec_name composition/output.mp4
# Must show: h264,video + aac,audio,2

ffmpeg -i output.mp4 -af "volumedetect" -f null - 2>&1 | grep mean_volume
# mean_volume should be between -20 and -10 dB (audible)
```

### Duration Check

```bash
ffprobe -v quiet -show_entries format=duration -of csv=p=0 output.mp4
# Should match data-duration on root div (±0.1s)
```

### Sync Check

Watch the rendered video and verify at these checkpoints:
- First 10s: S1 captions appear and disappear in sync with TTS
- ~8s: S2 "3000亿" caption appears when audio mentions it
- ~12s: "囤算力" appears as standalone caption
- ~26s: S3 transition happens cleanly
- Last 5s: CTA captions and fade-out complete before video ends

---

## Common Issues and Fixes

### "Captions lag behind audio" (most common)

**Symptom**: Captions appear 4-15s after the audio has already spoken that text.

**Root cause**: Scene boundaries set too late, or caption spacing too wide.

**Fix**: 
1. Recalculate scene boundaries from TTS script × expansion factor
2. Compress caption spacing within each scene
3. Shift all captions in the affected scene earlier

### "Caption stays too long / too short"

**Symptom**: Long text captions disappear while audio is still speaking; short captions linger.

**Fix**: Apply text-length-based duration formula (Phase 2.4). Never use uniform duration.

### "BGM has no sound"

**Symptom**: Rendered video only has TTS audio, no background music.

**Fix**:
1. Check files are real copies, not symlinks: `ls -la composition/bgm/`
2. Increase `data-volume` from 0.15 to 0.30-0.35
3. Verify no 404 errors in render output for BGM files
4. Check BGM tracks don't overlap on same track index

### "Scenes not switching"

**Symptom**: Video shows only the first scene throughout.

**Root cause**: GSAP timeline not registered correctly, or scene opacity not managed.

**Fix**:
1. Verify `window.__timelines["composition-id"] = tl` matches root div `data-composition-id`
2. Check scenes 2+ have `opacity: 0` in their style attribute
3. Verify all transition `tl.to()` and `tl.fromTo()` calls reference correct scene IDs

### "Silence detection gave wrong boundaries"

**Symptom**: Scene boundaries from silence detection don't match actual speech.

**Root cause**: Silence detection picks up sentence-internal pauses (0.5-0.8s) as scene boundaries.

**Fix**: Use TTS script timing × expansion factor as the primary timing source. Silence data is only a secondary reference for caption spacing within scenes.

### "Title says 万亿订单 but audio says 万亿账单"

**Symptom**: Caption text doesn't match what the TTS is saying.

**Fix**: Diff all caption text against `tts_script.md`. Remove any caption lines that don't appear in the TTS script. Add any TTS lines missing from captions.

---

## File Structure After Completion

```
project/
├── composition/
│   ├── index.html        # HyperFrames composition
│   ├── output.mp3        # TTS audio (copied, not symlink)
│   └── bgm/              # BGM files (copied, not symlink)
├── tts_script.md         # Ground truth for captions
├── ai_bill_presentation.html  # Source slides
└── ai_bill_video.mp4     # Rendered output
```
