---
name: pixabay-music-download
description: Download royalty-free BGM tracks from Pixabay Music. Use when the user needs background music, soundtrack, audio for presentations/videos/podcasts, wants to search and download MP3 files, or mentions Pixabay Music, royalty-free music, BGM, 背景音乐, 配乐, or 音效. Supports keyword search in multiple languages and downloading the top N results.
compatibility: opencli (required — browser strategy for page interaction), curl (for file downloads)
---

# Pixabay Music Download

Download royalty-free BGM tracks from Pixabay Music using opencli browser + curl. All tracks are free for commercial use under the Pixabay Content License.

## Prerequisites

```bash
opencli doctor  # must be green — requires Chrome + OpenCLI extension
```

## Workflow

### Step 1: Search Pixabay Music

Open the search page with URL-encoded keywords:

```bash
opencli browser open "https://pixabay.com/music/search/<keyword1>%20<keyword2>/"
opencli browser wait time 2
```

**Keyword mapping** — map user intent to English search terms:
| User wants | Search with |
|------------|-------------|
| 氛围 / 开场 / ambient | `ambient cinematic calm` |
| 节奏 / 科技 / electronic | `pulse electronic technology` |
| 思考 / 深度 / cello | `contemplation cello emotional` |
| 结尾 / 钢琴 / resolution | `resolution piano hopeful` |
| 史诗 / 宏大 / epic | `epic orchestral cinematic` |
| 轻快 / 欢乐 / upbeat | `upbeat happy corporate` |

Always confirm the keyword choice with the user before searching if unclear.

### Step 2: Extract track list from search results

The track links use CSS class `a.title--nya0C`. Extract title, URL path, and numeric ID:

```bash
opencli browser eval "JSON.stringify(Array.from(document.querySelectorAll('a.title--nya0C')).map(a=>{const m=a.getAttribute('href').match(/(\d+)\/$/);return{title:a.textContent.trim(),href:a.getAttribute('href'),id:m?m[1]:null}}))"
```

Returns JSON array: `[{"title":"Track Name","href":"/music/slug-123456/","id":"123456"}, ...]`

Present the top results to the user in a table. Let them choose which tracks to download, or pick the best match yourself based on title relevance.

### Step 3: Navigate to track page and extract download URL

For each chosen track, open its page and extract the MP3 URL from embedded JSON-LD structured data:

```bash
opencli browser open "https://pixabay.com/music/<slug>-<id>/"
opencli browser wait time 2
opencli browser eval "JSON.stringify(JSON.parse(Array.from(document.querySelectorAll('script[type=\"application/ld+json\"]')).find(s=>s.textContent.includes('contentUrl'))?.textContent||'{}').contentUrl||'not found')"
```

The `contentUrl` field in the JSON-LD `AudioObject` schema contains the direct CDN download link for the MP3 file.

### Step 4: Download the MP3

Use curl to download with a descriptive filename:

```bash
curl -L -o "<output_dir>/<track_name>.mp3" "<contentUrl>"
```

- Always use `-L` to follow redirects
- Sanitize filenames: replace spaces with underscores, remove special characters
- Suggested naming: `NN_category_trackname.mp3` (e.g., `01_ambient_cinematic.mp3`)

### Step 5: Verify and summarize

```bash
ls -lh <output_dir>/
```

Present a summary table to the user:

| File | Track | Artist | Size | Use Case |
|------|-------|--------|------|----------|
| `01_ambient.mp3` | Ambient Cinematic | AtlasAudio | 3.8M | Opening |

## Important notes

- **Pixabay tracks are free** for commercial use under the [Pixabay Content License](https://pixabay.com/service/license-summary/). No attribution required but appreciated.
- **Open track pages by direct URL**, not by clicking search result links. Clicking sometimes triggers a redirect to the login page. Direct URL navigation works reliably.
- **The download button on the page requires JavaScript**. Don't try to click it — use the JSON-LD `contentUrl` instead. This is more reliable and doesn't require login.
- **Close the browser when done**: `opencli browser close`
- If a search returns no results, try broader or different English keywords.
- If the JSON-LD extraction returns "not found", the page may not have fully loaded. Increase wait time or retry.
