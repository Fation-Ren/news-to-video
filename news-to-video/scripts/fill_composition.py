#!/usr/bin/env python3
"""HyperFrames 合成文件生成器 — 基于模板 + timing_reference.md + slides 填充
用法: python fill_composition.py <项目目录>
项目目录需包含:
  - timing_reference.md  (TTS锚点表)
  - tts/                 (TTS分段MP3 + 合并后的 output.mp3)
  - bgm/                 (BGM MP3文件*)
  - slides/index.html    (幻灯片HTML，提取场景视觉)

* 或指定: python fill_composition.py <项目目录> <bgm目录>
"""

import sys
import os
import re
import json
import shutil

# 模板路径（相对于 skill 目录）
TEMPLATE_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)),
                             "..", "ppt-to-video", "scripts", "composition-template.html")

# 过渡模式库
TRANSITIONS = {
    "slam-zoom": """
// {frm}→{tgt}: slam-zoom
tl.to("#{frm}", {{scale:1.06, opacity:0, duration:0.4, ease:"power3.in"}}, T.{tgt});
tl.fromTo("#{tgt}", {{scale:0.93, opacity:0}}, {{scale:1, opacity:1, duration:0.55, ease:"back.out(1.4)"}}, T.{tgt});
tl.set("#{frm}", {{visibility:"hidden"}}, T.{tgt}+0.45);""",
    "whip-pan": """
// {frm}→{tgt}: whip-pan
tl.to("#{frm}", {{x:-80, opacity:0, duration:0.4, ease:"power3.in"}}, T.{tgt});
tl.fromTo("#{tgt}", {{x:80, opacity:0}}, {{x:0, opacity:1, duration:0.55, ease:"power3.out"}}, T.{tgt});
tl.set("#{frm}", {{visibility:"hidden"}}, T.{tgt}+0.45);""",
    "fade-blur": """
// {frm}→{tgt}: fade-blur
tl.to("#{frm}", {{opacity:0, filter:"blur(8px)", duration:0.5, ease:"power2.in"}}, T.{tgt});
tl.fromTo("#{tgt}", {{opacity:0, filter:"blur(8px)"}}, {{opacity:1, filter:"blur(0px)", duration:0.6, ease:"power2.out"}}, T.{tgt});
tl.set("#{frm}", {{visibility:"hidden"}}, T.{tgt}+0.50);""",
    "slide-left": """
// {frm}→{tgt}: slide-left
tl.to("#{frm}", {{x:80, opacity:0, duration:0.4, ease:"power3.in"}}, T.{tgt});
tl.fromTo("#{tgt}", {{x:-80, opacity:0}}, {{x:0, opacity:1, duration:0.55, ease:"power3.out"}}, T.{tgt});
tl.set("#{frm}", {{visibility:"hidden"}}, T.{tgt}+0.45);""",
    "slide-up": """
// {frm}→{tgt}: slide-up
tl.to("#{frm}", {{y:-60, opacity:0, duration:0.4, ease:"power3.in"}}, T.{tgt});
tl.fromTo("#{tgt}", {{y:60, opacity:0}}, {{y:0, opacity:1, duration:0.55, ease:"power3.out"}}, T.{tgt});
tl.set("#{frm}", {{visibility:"hidden"}}, T.{tgt}+0.45);""",
    "zoom-blur": """
// {frm}→{tgt}: zoom-blur
tl.to("#{frm}", {{scale:1.08, opacity:0, duration:0.4, ease:"power3.in"}}, T.{tgt});
tl.fromTo("#{tgt}", {{scale:0.92, opacity:0}}, {{scale:1, opacity:1, duration:0.55, ease:"back.out(1.5)"}}, T.{tgt});
tl.set("#{frm}", {{visibility:"hidden"}}, T.{tgt}+0.45);""",
    "fade-black": """
// {frm}→{tgt}: fade-black
tl.to("#{frm}", {{opacity:0, duration:0.35, ease:"power3.in"}}, T.{tgt});
tl.fromTo("#{tgt}", {{opacity:0}}, {{opacity:1, duration:0.5, ease:"power2.out"}}, T.{tgt}+0.1);
tl.set("#{frm}", {{visibility:"hidden"}}, T.{tgt}+0.40);""",
    "scale-reveal": """
// {frm}→{tgt}: scale-reveal
tl.to("#{frm}", {{scale:0.94, opacity:0, duration:0.4, ease:"power3.in"}}, T.{tgt});
tl.fromTo("#{tgt}", {{scale:1.06, opacity:0}}, {{scale:1, opacity:1, duration:0.55, ease:"back.out(1.4)"}}, T.{tgt});
tl.set("#{frm}", {{visibility:"hidden"}}, T.{tgt}+0.45);""",
}

# 默认过渡顺序
DEFAULT_TRANSITION_SEQ = ["slam-zoom", "whip-pan", "zoom-blur", "fade-blur", "slide-up", "fade-black", "scale-reveal"]


def parse_timing_reference(filepath):
    """解析 timing_reference.md，返回 {anchors: [...], captions: [...], total_duration: float}"""
    with open(filepath, "r") as f:
        content = f.read()

    anchors = []
    captions = []
    total_duration = 0.0

    # 提取总时长
    m = re.search(r"总时长[：:]\s*([\d.]+)s", content)
    if m:
        total_duration = float(m.group(1))

    # 提取逐段锚点表
    in_table = False
    for line in content.split("\n"):
        if "逐段锚点" in line:
            in_table = True
            continue
        if in_table and line.startswith("|") and "mp3" in line:
            parts = [p.strip() for p in line.split("|") if p.strip()]
            if len(parts) >= 5:
                try:
                    anchors.append({
                        "segment": parts[0],
                        "file": parts[1],
                        "start": float(parts[2]),
                        "duration": float(parts[3]),
                        "end": float(parts[4]),
                    })
                except ValueError:
                    continue
        elif in_table and not line.startswith("|"):
            in_table = False

    # 提取字幕拆分
    current_scene = None
    in_cap_table = False
    for line in content.split("\n"):
        scene_match = re.match(r"###\s+S(\d+)\s+\([\d.]+-[\d.]+\)", line)
        if scene_match:
            current_scene = int(scene_match.group(1))
            in_cap_table = True
            continue
        if in_cap_table and line.startswith("|") and "C" in line:
            parts = [p.strip() for p in line.split("|") if p.strip()]
            if len(parts) >= 4:
                try:
                    captions.append({
                        "id": parts[0],
                        "text": parts[1],
                        "start": float(parts[2]),
                        "duration": float(parts[3]),
                        "scene": current_scene,
                    })
                except ValueError:
                    continue
        elif in_cap_table and line.strip() == "":
            in_cap_table = False

    return {"anchors": anchors, "captions": captions, "total_duration": total_duration}


def generate_t_variable(anchors):
    """从锚点生成 JS T 变量"""
    pairs = []
    for a in anchors:
        seg = a["segment"].replace("s", "s").replace("S", "s")
        pairs.append(f'{seg}:{a["start"]}')
    pairs.append(f'end:{anchors[-1]["end"] if anchors else 0}')
    return "{ " + ", ".join(pairs) + " }"


def generate_caps_array(captions):
    """从字幕列表生成 JS caps 数组"""
    items = []
    for i, c in enumerate(captions):
        items.append(f'{{t:{c["start"]},d:{c["duration"]},id:\'cap{i}\'}}')
    return "[\n  " + ",\n  ".join(items) + "\n]"


def generate_transitions(anchors, seq=None):
    """生成场景过渡 JS 代码"""
    if seq is None:
        seq = DEFAULT_TRANSITION_SEQ
    lines = []
    for i in range(len(anchors) - 1):
        frm = f's{i+1}'
        to = f's{i+2}'
        pattern_name = seq[i % len(seq)]
        pattern = TRANSITIONS.get(pattern_name, TRANSITIONS["slam-zoom"])
        lines.append(pattern.format(frm=frm, tgt=to))
    return "\n".join(lines)


def generate_bgm_tags(bgm_dir, anchors):
    """生成 BGM audio 标签"""
    if not os.path.isdir(bgm_dir):
        return "  <!-- BGM directory not found -->"

    mp3_files = sorted([f for f in os.listdir(bgm_dir) if f.endswith(".mp3")])
    if not mp3_files:
        return "  <!-- No BGM files found -->"

    tags = []
    for i, mp3 in enumerate(mp3_files[:len(anchors)]):
        track = i + 1
        start = anchors[i]["start"] if i < len(anchors) else 0
        dur = anchors[-1]["end"] - start if i == len(mp3_files) - 1 else anchors[i + 1]["start"] - start
        tags.append(
            f'  <audio id="bgm{track}" data-start="{start}" '
            f'data-duration="{dur:.2f}" data-track-index="{track}" '
            f'src="bgm/{mp3}" data-volume="0.32"></audio>'
        )
    return "\n".join(tags)


def generate_caption_divs(captions):
    """生成字幕 div"""
    lines = []
    for i, c in enumerate(captions):
        lines.append(f'  <div id="cap{i}" class="caption">{c["text"]}</div>')
    return "\n".join(lines)


def fill_template(template_path, project_dir, bgm_dir=None):
    """填充模板，写入 composition/index.html"""
    if not os.path.exists(template_path):
        print(f"[错误] 模板不存在: {template_path}")
        sys.exit(1)

    timing_path = os.path.join(project_dir, "timing_reference.md")
    if not os.path.exists(timing_path):
        print(f"[错误] timing_reference.md 不存在: {timing_path}")
        sys.exit(1)

    slides_path = os.path.join(project_dir, "slides", "index.html")
    tts_path = os.path.join(project_dir, "composition", "output.mp3")
    if bgm_dir is None:
        bgm_dir = os.path.join(project_dir, "composition", "bgm")

    print(f"=== 填充合成文件 ===")
    print(f"项目目录: {project_dir}")
    print(f"模板: {template_path}")

    # 解析数据
    timing = parse_timing_reference(timing_path)
    anchors = timing["anchors"]
    captions = timing["captions"]
    print(f"锚点: {len(anchors)} 段  字幕: {len(captions)} 条  时长: {timing['total_duration']}s")

    if not anchors:
        print("[错误] 未解析到锚点数据")
        sys.exit(1)

    # 场景数
    scene_count = len(anchors)

    # 读取模板
    with open(template_path, "r") as f:
        template = f.read()

    # 项目配置 — 从幻灯片提取或使用默认值
    width, height = 1080, 1920
    title = "Video"
    bg_color = "#050d1a"
    bg_rgb = "5,13,26"
    accent_color = "#c8a44e"
    accent_rgb = "200,164,78"
    text_color = "#f0f0f0"
    sub_text_color = "#8899aa"
    comp_id = "composition"

    # 尝试从 slides HTML 提取样式
    if os.path.exists(slides_path):
        with open(slides_path, "r") as f:
            slide_html = f.read()
        title_match = re.search(r"<title>(.*?)</title>", slide_html)
        if title_match:
            title = title_match.group(1)
        bg_match = re.search(r"--bg-deep:\s*([#\w]+)", slide_html)
        if bg_match:
            bg_color = bg_match.group(1)
        accent_match = re.search(r"--accent-neon:\s*([#\w]+)", slide_html)
        if accent_match:
            accent_color = accent_match.group(1)
        elif accent_match := re.search(r"--accent-gold:\s*([#\w]+)", slide_html):
            accent_color = accent_match.group(1)
        text_match = re.search(r"--text-primary:\s*([#\w]+)", slide_html)
        if text_match:
            text_color = text_match.group(1)

    # 从项目目录名或标题生成 comp_id
    dir_name = os.path.basename(os.path.abspath(project_dir))
    comp_id = re.sub(r"[^a-zA-Z0-9_-]", "", dir_name.replace(" ", "-"))[:30]
    if not comp_id or comp_id[0].isdigit():
        comp_id = "v" + comp_id if comp_id else "video-comp"
    # 转小写
    comp_id = comp_id.lower()

    # 颜色转 RGB
    def hex_to_rgb(h):
        h = h.lstrip("#")
        return ",".join(str(int(h[i:i+2], 16)) for i in (0, 2, 4))

    bg_rgb = hex_to_rgb(bg_color)
    accent_rgb = hex_to_rgb(accent_color)

    # 生成各部分
    t_var = generate_t_variable(anchors)
    caps_arr = generate_caps_array(captions)
    transitions_js = generate_transitions(anchors)
    bgm_tags = generate_bgm_tags(bgm_dir, anchors)
    cap_divs = generate_caption_divs(captions)

    # 确认 TTS 音频
    tts_duration = timing["total_duration"]

    # 替换占位符
    replacements = {
        "{{WIDTH}}": str(width),
        "{{HEIGHT}}": str(height),
        "{{TITLE}}": title,
        "{{BG_COLOR}}": bg_color,
        "{{BG_RGB}}": bg_rgb,
        "{{ACCENT_COLOR}}": accent_color,
        "{{ACCENT_RGB}}": accent_rgb,
        "{{BLUE_COLOR}}": "#1a6bff",
        "{{CYAN_COLOR}}": "#00d4aa",
        "{{TEXT_COLOR}}": text_color,
        "{{SUB_TEXT_COLOR}}": sub_text_color,
        "{{COMP_ID}}": comp_id,
        "{{TTS_DURATION}}": str(tts_duration),
        "{{T_VARIABLE}}": t_var,
        "{{CAPS_ARRAY}}": caps_arr,
        "{{TRANSITIONS}}": transitions_js,
        "{{BGM_TAGS}}": bgm_tags,
        "{{CAPTION_DIVS}}": cap_divs,
        "{{PROJECT_CSS}}": "/* Project-specific styles — add from slides */",
        "{{SCENE_HTML}}": "  <!-- Scene HTML — copy from slides/index.html -->",
        "{{ENTRY_ANIMATIONS}}": "  /* Entry animations — add per scene */",
    }

    for placeholder, value in replacements.items():
        template = template.replace(placeholder, value)

    # 写入
    out_dir = os.path.join(project_dir, "composition")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "index.html")
    with open(out_path, "w") as f:
        f.write(template)

    print(f"\n[完成] {out_path}")
    print(f"  场景: {scene_count}  字幕: {len(captions)}  时长: {tts_duration}s")
    print(f"  下一步: 手动填充 {{SCENE_HTML}} 和 {{ENTRY_ANIMATIONS}}")
    return out_path


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    project_dir = sys.argv[1]
    bgm_dir = sys.argv[2] if len(sys.argv) > 2 else None
    fill_template(TEMPLATE_PATH, project_dir, bgm_dir)


if __name__ == "__main__":
    main()
