"""Tiny documents for the extraction tests, built in code (no binary fixtures).

`make_pdf` writes a minimal valid PDF: one Helvetica font, one text line per page. With
`unicode=True` the page text may be any Unicode (e.g. Marathi): each distinct character gets a
one-byte code and a ToUnicode CMap maps it back, as a properly embedded Unicode font does.
Without it the text is written as plain Latin-1 bytes, which is what a legacy (non-Unicode)
Marathi font such as Kruti Dev / Shree-Lipi leaves in the text layer.
"""

from __future__ import annotations

# The opening of a Maharashtra GR (with the Unicode text layer intact).
MARATHI = (
    "महाराष्ट्र शासन कृषी विभाग शासन निर्णय क्रमांक फळबाग २०२५ "
    "भाऊसाहेब फुंडकर फळबाग लागवड योजना प्रति हेक्टर अनुदान"
)
# The same heading as a Kruti Dev font leaves it in the text layer (ASCII garbage).
KRUTI_DEV = "egkjk\"Vª 'kklu Ñf\"k foHkkx 'kklu fu.kZ; Øekad QGckx ykxoM ;kstuk izfr gsDVj vuqnku"
# Shree-Lipi style: accented Latin-1 garbage.
SHREE_LIPI = "´ÖÆüÖ¸üÖ™Òü ¿ÖÖÃÖ®Ö ÛúéÂÖß ×¾Ö³ÖÖÝÖ ¿ÖÖÃÖ®Ö ×®ÖÞÖÔµÖ ÛÎú´ÖÖÓÛú ±úôû²ÖÖÝÖ"  # noqa: RUF001
# Mostly private-use code points (a font whose glyphs were never mapped to Unicode).
PUA = "".join(chr(0xE000 + i % 64) for i in range(60)) + " शासन"
# A Unicode text layer with the vowel signs pulled in front of their consonants.
SHUFFLED = "ि नर्णय ि वभाग ि कसान ि नधी ि पक ि वमा ि दनांक ि जल्हा ि वकास ि वहीर"
ENGLISH = (
    "Government of Maharashtra, Agriculture Department. Resolution on the subsidy for the "
    "planting of fruit orchards: the amount shall be paid to the farmers who apply by the "
    "last date and the scheme is valid for this year."
)


def _hex(data: bytes) -> bytes:
    return b"<" + data.hex().encode() + b">"


def _cmap(codes: dict[str, int]) -> bytes:
    lines = [
        "/CIDInit /ProcSet findresource begin 12 dict begin begincmap",
        "/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def",
        "/CMapName /Adobe-Identity-UCS def /CMapType 2 def",
        "1 begincodespacerange <00> <FF> endcodespacerange",
        f"{len(codes)} beginbfchar",
    ]
    lines += [f"<{code:02X}> <{ord(ch):04X}>" for ch, code in codes.items()]
    lines += ["endbfchar endcmap CMapName currentdict /CMap defineresource pop end end"]
    return "\n".join(lines).encode()


def make_pdf(pages: list[str], *, unicode: bool = False) -> bytes:
    codes: dict[str, int] = {}
    if unicode:
        for ch in sorted(set("".join(pages))):
            codes[ch] = 0x20 if ch == " " else 0x21 + len([c for c in codes if c != " "])
        assert max(codes.values()) < 0xFF

    def encode(text: str) -> bytes:
        if unicode:
            return bytes(codes[ch] for ch in text)
        return text.encode("latin-1")

    objects: list[bytes] = []
    n_fixed = 4 if unicode else 3
    kids = " ".join(f"{n_fixed + 1 + 2 * i} 0 R" for i in range(len(pages)))
    objects.append(b"<< /Type /Catalog /Pages 2 0 R >>")
    objects.append(f"<< /Type /Pages /Kids [{kids}] /Count {len(pages)} >>".encode())
    font = b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica"
    font += b" /ToUnicode 4 0 R >>" if unicode else b" /Encoding /WinAnsiEncoding >>"
    objects.append(font)
    if unicode:
        cmap = _cmap(codes)
        objects.append(b"<< /Length %d >>\nstream\n" % len(cmap) + cmap + b"\nendstream")
    for i, text in enumerate(pages):
        content = b"BT /F1 12 Tf 72 720 Td " + _hex(encode(text)) + b" Tj ET" if text else b""
        page = (
            "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
            f"/Resources << /Font << /F1 3 0 R >> >> /Contents {n_fixed + 2 + 2 * i} 0 R >>"
        )
        objects.append(page.encode())
        objects.append(b"<< /Length %d >>\nstream\n" % len(content) + content + b"\nendstream")
    out = bytearray(b"%PDF-1.4\n")
    offsets = []
    for n, body in enumerate(objects, start=1):
        offsets.append(len(out))
        out += b"%d 0 obj\n" % n + body + b"\nendobj\n"
    xref = len(out)
    out += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objects) + 1)
    out += b"".join(b"%010d 00000 n \n" % o for o in offsets)
    out += b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (
        len(objects) + 1,
        xref,
    )
    return bytes(out)


HTML = """<!doctype html><html><head><meta charset="utf-8"><title>शासन निर्णय</title>
<style>body { color: red }</style><script>var amount = "₹ 99,99,999";</script></head>
<body><nav>मुख्य पान</nav><h1>फळबाग लागवड योजना</h1>
<p>प्रति हेक्टर &#8377; १,००,००० अनुदान.</p><noscript>JavaScript लागेल</noscript>
<p>अर्जाची अंतिम मुदत ३१ डिसेंबर.</p></body></html>"""
