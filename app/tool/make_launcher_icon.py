"""Draws the BagMitra launcher icon (audit R3): a santra (orange) with a leaf on the brand
leaf green. Writes the master images to app/assets/icon/ and the Android launcher images
(legacy, adaptive foreground and Android 13 monochrome) and the white status-bar notification
icon into android/app/src/main/res/.

Run from app/:  python3 tool/make_launcher_icon.py   (needs Pillow)
Colours are the brand tokens in lib/theme/tokens.dart (leaf, leaf2, leaf3, santra, santra2).
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

LEAF = (0x1F, 0x4D, 0x2B, 255)
LEAF2 = (0x2E, 0x6B, 0x3C, 255)
LEAF3 = (0x9B, 0xC7, 0x9A, 255)
SANTRA = (0xF2, 0x8C, 0x28, 255)
SANTRA2 = (0xFF, 0xB1, 0x5C, 255)
SANTRA_DEEP = (0xA3, 0x4A, 0x06, 255)
WHITE = (255, 255, 255, 255)

APP = Path(__file__).resolve().parents[1]
RES = APP / "android" / "app" / "src" / "main" / "res"
ICON_DIR = APP / "assets" / "icon"
SS = 4  # supersampling for smooth edges

LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ADAPTIVE = {k: v * 108 // 48 for k, v in LEGACY.items()}
NOTIFY = {k: v // 2 for k, v in LEGACY.items()}  # 24 dp status-bar icon


def _fruit(draw: ImageDraw.ImageDraw, s: float, mono: bool) -> None:
    """The fruit and leaf on a 108-unit adaptive canvas (safe zone: the centre 66 units)."""

    def box(cx: float, cy: float, r: float) -> tuple[float, float, float, float]:
        return (cx - r) * s, (cy - r) * s, (cx + r) * s, (cy + r) * s

    body = WHITE if mono else SANTRA
    draw.ellipse(box(54, 58, 22), fill=body)
    if not mono:
        draw.ellipse(box(47, 51, 7), fill=SANTRA2)  # light catching the peel
        draw.ellipse(box(54, 37.5, 2.2), fill=SANTRA_DEEP)  # where the stem joins
    # Stem and leaf, up and to the right.
    stem = WHITE if mono else LEAF
    draw.line([(54 * s, 38 * s), (57 * s, 31 * s)], fill=stem, width=round(2.4 * s))
    leaf = [(57, 32), (63, 25), (72, 23), (70, 31), (62, 35)]
    draw.polygon([(x * s, y * s) for x, y in leaf], fill=WHITE if mono else LEAF3)
    if not mono:
        draw.line([(58 * s, 32 * s), (70 * s, 24.5 * s)], fill=LEAF2, width=round(1.2 * s))


def foreground(px: int, mono: bool = False) -> Image.Image:
    big = Image.new("RGBA", (px * SS, px * SS), (0, 0, 0, 0))
    _fruit(ImageDraw.Draw(big), px * SS / 108, mono)
    return big.resize((px, px), Image.Resampling.LANCZOS)


def full(px: int, round_mask: bool) -> Image.Image:
    """The legacy (pre-Android 8) icon: background and fruit, round or rounded square."""
    big = Image.new("RGBA", (px * SS, px * SS), (0, 0, 0, 0))
    mask = Image.new("L", big.size, 0)
    md = ImageDraw.Draw(mask)
    if round_mask:
        md.ellipse((0, 0, big.width - 1, big.height - 1), fill=255)
    else:
        md.rounded_rectangle((0, 0, big.width - 1, big.height - 1), radius=big.width // 5, fill=255)
    bg = Image.new("RGBA", big.size, LEAF)
    big.paste(bg, (0, 0), mask)
    # The legacy icon shows the full 108 canvas scaled into 48: zoom so the fruit fills it.
    fruit = foreground(round(px * SS * 108 / 72))
    off = (fruit.width - big.width) // 2
    big.alpha_composite(fruit.crop((off, off, off + big.width, off + big.height)))
    return big.resize((px, px), Image.Resampling.LANCZOS)


def notify(px: int) -> Image.Image:
    """White silhouette for the status bar. A notification small icon must not be the adaptive
    launcher icon (Android 8.0 cannot draw one there)."""
    mono = foreground(round(px * 108 / 60), mono=True)
    off = (mono.width - px) // 2
    return mono.crop((off, off, off + px, off + px))


def main() -> None:
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    full(1024, round_mask=False).save(ICON_DIR / "icon.png")
    foreground(1024).save(ICON_DIR / "foreground.png")
    foreground(1024, mono=True).save(ICON_DIR / "monochrome.png")
    for density, px in LEGACY.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(exist_ok=True)
        full(px, round_mask=False).save(folder / "ic_launcher.png", optimize=True)
        fg = ADAPTIVE[density]
        foreground(fg).save(folder / "ic_launcher_foreground.png", optimize=True)
        foreground(fg, mono=True).save(folder / "ic_launcher_monochrome.png", optimize=True)
        drawables = RES / f"drawable-{density}"
        drawables.mkdir(exist_ok=True)
        notify(NOTIFY[density]).save(drawables / "ic_stat_notify.png", optimize=True)


if __name__ == "__main__":
    main()
