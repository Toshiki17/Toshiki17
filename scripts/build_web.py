#!/usr/bin/env python3
"""web/nakabisha_sp.html から、iOSアプリに同梱する ios/www/ を作る。

  python3 scripts/build_web.py

やること
  1. doctype・viewport・[hidden] の非表示など、Artifact の外で開くときに必要な <head> とスタイルを補う
  2. Google Fonts を端末内に同梱し（ページで使う文字を含むサブセットだけ）、オフラインでも同じ書体で表示する
  3. iPhoneのファイル選択で .kif が灰色にならないよう、accept 属性を外す
  4. 「ブラウザに保存」などの文言をアプリ向けに直す
"""
import os
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "web", "nakabisha_sp.html")
OUT = os.path.join(ROOT, "ios", "www")
FONTS_URL = ("https://fonts.googleapis.com/css2?family=Shippori+Mincho+B1:wght@600;800"
             "&family=Zen+Kaku+Gothic+New:wght@400;500;700&display=swap")
# woff2 と unicode-range 付きのCSSを返してもらうため、Safariとして取得する
UA = ("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 "
      "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1")

HEAD = """<!doctype html>
<html lang="ja">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">
<meta name="color-scheme" content="light dark">
<style>[hidden]{display:none!important}body{margin:0}html{-webkit-text-size-adjust:100%;-webkit-user-select:none;user-select:none}textarea,input{-webkit-user-select:text;user-select:text}</style>
"""


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def replace_once(html, old, new):
    if html.count(old) != 1:
        sys.exit(f"置換対象が1か所ではありません: {old[:60]!r}")
    return html.replace(old, new)


def in_ranges(ranges, chars):
    for r in ranges.split(","):
        a, _, z = r.strip()[2:].partition("-")
        a = int(a, 16)
        z = int(z, 16) if z else a
        if any(a <= c <= z for c in chars):
            return True
    return False


def build_fonts(html):
    css = fetch(FONTS_URL).decode()
    chars = {ord(c) for c in html}
    chars |= {int(h, 16) for h in re.findall(r"\\u([0-9a-fA-F]{4})", html)}
    font_dir = os.path.join(OUT, "fonts")
    os.makedirs(font_dir, exist_ok=True)
    keep = []
    for block in re.findall(r"@font-face\s*\{.*?\}", css, re.S):
        ranges = re.search(r"unicode-range:\s*([^;]+);", block).group(1)
        if not in_ranges(ranges, chars):
            continue
        url = re.search(r"url\((https://fonts\.gstatic\.com/s/[^)]+)\)", block).group(1)
        name = url.split("/s/", 1)[1].replace("/", "_")
        path = os.path.join(font_dir, name)
        if not os.path.exists(path):
            with open(path, "wb") as f:
                f.write(fetch(url))
        keep.append(block.replace(url, "fonts/" + name))
    used = {b.split("fonts/", 1)[1].split(")", 1)[0] for b in keep}
    for name in os.listdir(font_dir):
        if name not in used:
            os.remove(os.path.join(font_dir, name))
    with open(os.path.join(OUT, "fonts.css"), "w") as f:
        f.write("\n".join(keep) + "\n")
    print(f"fonts: {len(keep)} files")


def main():
    with open(SRC, encoding="utf-8") as f:
        html = f.read()

    html = replace_once(html, "<title>中飛車道場 スマホ版</title>", "<title>中飛車道場</title>")
    html = re.sub(r'<link rel="preconnect" href="https://fonts\.googleapis\.com">\n?', "", html)
    html = re.sub(r'<link rel="stylesheet" href="https://fonts\.googleapis\.com/[^"]*">',
                  '<link rel="stylesheet" href="fonts.css">', html)
    if "fonts.googleapis.com" in html:
        sys.exit("Google Fonts の参照が残っています")
    html = replace_once(html, ' id="kifFile" accept=".kif,.kifu,.txt,text/plain"', ' id="kifFile"')
    html = replace_once(html, "記録はこの端末のブラウザにだけ保存されます。", "記録はこの端末にだけ保存されます。")
    html = HEAD + html

    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8") as f:
        f.write(html)
    build_fonts(html)
    print("wrote", os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
    main()
