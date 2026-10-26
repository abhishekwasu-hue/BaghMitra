"""Fails when a Markdown file links to a repository path that does not exist.

Only relative links are checked (no network): external URLs and in-page anchors are skipped.
"""

import pathlib
import re
import sys

LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
SKIP_DIRS = {".git", "node_modules", "build", ".dart_tool", ".venv"}


def main() -> int:
    root = pathlib.Path(".").resolve()
    broken = []
    for md in root.rglob("*.md"):
        if SKIP_DIRS & set(md.relative_to(root).parts):
            continue
        text = md.read_text(encoding="utf-8", errors="replace")
        # Links inside code spans/blocks are examples, not links.
        text = re.sub(r"```.*?```", "", text, flags=re.S)
        text = re.sub(r"`[^`\n]*`", "", text)
        for target in LINK.findall(text):
            if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("#"):
                continue
            path = target.split("#", 1)[0]
            if not path:
                continue
            resolved = (
                (root / path.lstrip("/"))
                if path.startswith("/")
                else (md.parent / path)
            )
            if not resolved.exists():
                broken.append(f"{md.relative_to(root)}: {target}")
    for line in broken:
        print(line)
    print(f"{len(broken)} broken relative link(s)")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
