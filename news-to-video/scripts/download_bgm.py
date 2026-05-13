#!/usr/bin/env python3
"""Pixabay BGM 下载脚本 — 搜索并下载免版税背景音乐
通过 opencli browser 访问 Pixabay（绕过反爬），requests 下载 MP3。
用法: python download_bgm.py <关键词> <输出目录> [数量]
示例: python download_bgm.py "epic scifi technology" ./bgm 3
"""

import sys
import os
import json
import re
import time
import subprocess
import requests

PIXABAY_BASE = "https://pixabay.com"
PIXABAY_MUSIC = "https://pixabay.com/music"


def run_opencli(args, timeout=30, stdin_text=None):
    """运行 opencli 命令，返回 stdout。stdin_text 通过管道传入"""
    cmd = ["opencli"] + args
    result = subprocess.run(
        cmd, capture_output=True, text=True, timeout=timeout,
        input=stdin_text
    )
    # 过滤 stderr 中的 update 提示
    return result.stdout.strip()


def search_tracks(keyword, count=10):
    """通过 opencli browser 搜索 Pixabay Music，返回 track 列表"""
    query = keyword.replace(" ", "%20")
    url = f"{PIXABAY_MUSIC}/search/{query}/"
    print(f"[搜索] {url}")

    # 打开搜索页
    run_opencli_shell(f'browser open "{url}"')
    time.sleep(4)

    # 提取 track 列表 — 用单引号包裹JS，内部用双引号
    js = (
        'JSON.stringify(Array.from(document.querySelectorAll("a.title--nya0C"))'
        f'.slice(0,{count}).map(function(a){{'
        'var m=a.getAttribute("href").match(/(\\d+)\\/$/);'
        'return{title:a.textContent.trim(),href:a.getAttribute("href"),id:m?m[1]:null}'
        '}))'
    )
    result = run_opencli_shell(f"browser eval '{js}'")
    try:
        tracks = json.loads(result)
        if tracks:
            print(f"  找到 {len(tracks)} 个 track")
            return tracks
    except json.JSONDecodeError:
        pass

    # 备用：宽松匹配
    js2 = (
        'JSON.stringify(Array.from(document.querySelectorAll("a[href*=/music/]"))'
        f'.filter(function(a){{return /\\d+\\/$/.test(a.getAttribute("href"))}})'
        f'.slice(0,{count}).map(function(a){{'
        'var m=a.getAttribute("href").match(/(\\d+)\\/$/);'
        'var t=a.textContent.trim()||"untitled";'
        'return{title:t.slice(0,80),href:a.getAttribute("href"),id:m?m[1]:null}'
        '}))'
    )
    result = run_opencli_shell(f"browser eval '{js2}'")
    try:
        tracks = json.loads(result)
        if tracks:
            print(f"  备用策略找到 {len(tracks)} 个 track")
            return tracks
    except json.JSONDecodeError:
        pass

    print("  [失败] 未找到 track")
    return []


def run_opencli_shell(args_str, timeout=30):
    """通过 shell=True 运行 opencli，避免列表参数引号转义"""
    result = subprocess.run(
        f"opencli {args_str}",
        shell=True, capture_output=True, text=True, timeout=timeout
    )
    return result.stdout.strip()


def get_download_url(href):
    """打开 track 页，从 AudioObject JSON-LD 提取 contentUrl"""
    url = f"{PIXABAY_BASE}{href}"
    run_opencli_shell(f'browser open "{url}"')
    time.sleep(4)

    # JS 内部用双引号，shell 用单引号包裹 -> 无转义冲突
    # 注意: "ld+json" 中的 + 在 CSS 选择器中需转义，改用 indexOf 过滤
    js = (
        'JSON.stringify('
        'Array.from(document.querySelectorAll("script[type]"))'
        '.filter(function(s){return s.type.indexOf("ld+json")>=0})'
        '.map(function(s){try{var d=JSON.parse(s.textContent);'
        'if(d["@type"]==="AudioObject")return d.contentUrl}catch(e){}})'
        '.filter(Boolean))'
    )
    result = run_opencli_shell(f"browser eval '{js}'")

    # 从结果提取 mp3 URL
    mp3_match = re.search(r'https://cdn\.pixabay\.com/[^\s"\']+\.mp3[^\s"\']*', result)
    if mp3_match:
        return mp3_match.group(0).rstrip('\"]')

    return "not found"


def download_mp3(url, filepath):
    """下载 MP3 文件"""
    print(f"  [下载] {os.path.basename(filepath)}")
    resp = requests.get(url, stream=True, timeout=120)
    resp.raise_for_status()
    with open(filepath, "wb") as f:
        for chunk in resp.iter_content(chunk_size=16384):
            f.write(chunk)
    size_mb = os.path.getsize(filepath) / (1024 * 1024)
    print(f"  -> {os.path.basename(filepath)} ({size_mb:.1f} MB)")


def main():
    keyword = sys.argv[1] if len(sys.argv) > 1 else "epic technology"
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "./bgm"
    count = int(sys.argv[3]) if len(sys.argv) > 3 else 3

    os.makedirs(out_dir, exist_ok=True)

    print(f"=== Pixabay BGM 下载 ===")
    print(f"关键词: {keyword}  数量: {count}  输出: {out_dir}")

    # 检查 opencli 可用性
    check = subprocess.run("opencli doctor", shell=True, capture_output=True, text=True, timeout=10)
    if "Extension: connected" not in check.stdout:
        print("[错误] opencli browser 未连接。请打开 Chrome 并确保 opencli 扩展已启用。")
        sys.exit(1)

    tracks = search_tracks(keyword, count=min(count + 5, 20))

    if not tracks:
        print("[错误] 未找到匹配的音乐")
        sys.exit(1)

    print(f"\n找到 {len(tracks)} 首曲目，下载前 {count} 首:")
    downloaded = 0
    for i, track in enumerate(tracks):
        if downloaded >= count:
            break
        title = track["title"].strip()
        print(f"\n[{downloaded+1}/{count}] {title} (id={track['id']})")

        dl_url = get_download_url(track["href"])
        if dl_url == "not found":
            print(f"  [跳过] 无法获取下载链接")
            continue

        safe_name = re.sub(r"[^a-zA-Z0-9_\-]", "", title.replace(" ", "_"))[:60]
        filename = f"{downloaded+1:02d}_{safe_name}.mp3"
        filepath = os.path.join(out_dir, filename)

        try:
            download_mp3(dl_url, filepath)
            downloaded += 1
        except Exception as e:
            print(f"  [失败] {e}")

    print(f"\n=== 完成: {downloaded}/{count} 首已下载 ===")


if __name__ == "__main__":
    main()
