"""The HTML shell shared by the public pages: one inline stylesheet, no scripts, no assets.

Colours are the app's brand tokens (`app/lib/theme/tokens.dart`, `BmPalette`): leaf greens,
santra orange, cream background, ink text, and the night palette for dark mode.
"""

from __future__ import annotations

from html import escape

CSS = """
:root{--bg:#F3F7EE;--card:#FFFFFF;--ink:#1B2A1E;--muted:#4E6153;--line:#E3EAD9;
--brand:#1F4D2B;--brand2:#2E6B3C;--accent:#F28C28;--link:#A34A06;--soft:#EEF6EC}
@media (prefers-color-scheme:dark){:root{--bg:#0F1A12;--card:#18271B;--ink:#E8F0E3;
--muted:#A9BCA9;--line:#2A3D2E;--brand:#9BC79A;--brand2:#9BC79A;--link:#FFB15C;
--soft:#213826}}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--bg);color:var(--ink);line-height:1.6;font-size:17px;
font-family:"Noto Sans Devanagari","Mukta",system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;
overflow-wrap:anywhere}
header{background:linear-gradient(135deg,#1F4D2B,#2E6B3C);color:#FFFFFF;
padding:20px 16px 18px;border-bottom:4px solid var(--accent)}
header .in,main{max-width:760px;margin:0 auto}
header h1{margin:0;font-size:1.5rem;line-height:1.3}
header p{margin:4px 0 0;opacity:.92}
header a{color:#FFFFFF}
main{padding:8px 16px 32px}
section{background:var(--card);border:1px solid var(--line);border-radius:14px;
padding:4px 16px 12px;margin:14px 0}
h2{color:var(--brand);font-size:1.2rem;line-height:1.35;margin:14px 0 6px}
h3{color:var(--brand2);font-size:1.02rem;margin:12px 0 2px}
p,ul{margin:6px 0}
ul{padding-left:1.2em}
li{margin:3px 0}
a{color:var(--link)}
.lang{display:flex;flex-wrap:wrap;gap:8px;margin:12px 0 0}
.lang a{background:var(--soft);color:var(--brand);border-radius:999px;padding:6px 14px;
text-decoration:none;font-weight:600}
header .lang a{background:rgba(255,255,255,.16);color:#FFFFFF}
.note{color:var(--muted);font-size:.93rem}
.if{display:inline-block;background:var(--soft);color:var(--brand);border-radius:6px;
padding:0 6px;font-size:.86rem;font-weight:600}
footer{color:var(--muted);font-size:.9rem;text-align:center;padding:0 16px 28px}
""".strip()


def page(*, lang: str, title: str, header: str, body: str, footer: str) -> str:
    """A complete HTML document. `header`, `body` and `footer` are trusted page markup."""
    return (
        "<!doctype html>"
        f'<html lang="{escape(lang)}"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        '<meta name="color-scheme" content="light dark">'
        f"<title>{escape(title)}</title><style>{CSS}</style></head><body>"
        f'<header><div class="in">{header}</div></header>'
        f"<main>{body}</main><footer>{footer}</footer></body></html>"
    )
