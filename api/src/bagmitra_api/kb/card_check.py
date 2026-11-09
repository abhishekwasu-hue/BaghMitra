"""Q128 (owner 2026-11-09): there is no human expert; the AI checks every knowledge-card point
against the source document the point cites.

Usage (one-off, on the VPS where FEED_AI_API_KEY is set; runbook kb-sources.md):
    python -m bagmitra_api.kb.card_check CARDS_JSON|- [--only SOURCE_KEY ...] > report.md
("-" reads the cards file from stdin: the API image does not contain the app's assets.)

A "point" is every object in the cards file with `labels` and `source_keys` (card items,
profile parts such as symptoms, preparations). For each cited source the document is fetched
(PDF or HTML, same extractor as the government feed), then:
1. number check, no AI: every number and date in the point (en, mr and hi) must be in the text
   of its cited sources (the `feed.output_check` rule the news articles use);
2. AI check, only with FEED_AI_API_KEY: the model reads the passages of the source that share
   the most words with the points and answers per point `supported` / `contradicted` /
   `not_found` with a verbatim quote, checked against the source text: the model is never
   trusted on its word.
A verdict whose quote is not in the source is reported as `unverified_quote` (the model's
own verdict is kept beside it), so a failed quote match is never mistaken for a missing point.
The model is told what each source is cited for (the point's `source` note): a point that
combines several sources is judged, per document, only on the part that document is cited for.
A point passes when one cited source supports it and the number check finds nothing. The tool
only writes a report; it changes no card.
"""

from __future__ import annotations

import asyncio
import json
import re
import sys
from collections.abc import Iterator, Mapping
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Protocol

import httpx

from bagmitra_api.core.settings import Settings, get_settings
from bagmitra_api.feed.extract import extract
from bagmitra_api.feed.output_check import check_output, normalise
from bagmitra_api.kb.fetcher import MAX_DOCUMENT_BYTES, USER_AGENT

VERDICTS = ("supported", "contradicted", "not_found")
LANGS = ("en", "mr", "hi")
WINDOW_CHARS = 1500
WINDOWS_PER_POINT = 4
MIN_WORD_LEN = 4

CHECK_PROMPT = """You check advice cards for orange and sweet-lime farmers against the official
document each card cites. The user message has passages of that document and numbered points.
Each point says what the document is cited for ("cited as"). A point may combine several
sources: judge only the part this document is cited for. A range or a list that includes what
the document states, with the rest cited to another source, is supported, not contradicted.
For every point answer from the document text only, never from general knowledge:
- "supported": the document gives the same advice (same measure, product, dose, timing and
  numbers). quote = the sentence(s) that say so, copied character for character.
- "contradicted": the document says something different (another dose, timing, product or
  number for the same thing). quote = the conflicting sentence, copied character for character.
- "not_found": the passages do not state it. quote = "".
Quote one passage without "…" or gaps; never paraphrase a quote. Answer once for every id."""

CHECK_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "required": ["points"],
    "properties": {
        "points": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["id", "verdict", "quote"],
                "properties": {
                    "id": {"type": "string"},
                    "verdict": {"type": "string", "enum": list(VERDICTS)},
                    "quote": {"type": "string"},
                },
            },
        }
    },
}


@dataclass(frozen=True, slots=True)
class Point:
    id: str
    labels: Mapping[str, str]
    source_keys: tuple[str, ...]
    cited_as: str = ""


@dataclass(slots=True)
class Result:
    point: Point
    number_issues: list[str] = field(default_factory=list)
    # source key -> (verdict, quote); "unreadable" when the document could not be read.
    verdicts: dict[str, tuple[str, str]] = field(default_factory=dict)

    @property
    def verdict(self) -> str:
        found = {v for v, _ in self.verdicts.values()}
        for verdict in ("supported", "contradicted", "unverified_quote", "not_found", "unreadable"):
            if verdict in found:
                return verdict
        return "not_checked"

    @property
    def passed(self) -> bool:
        return self.verdict == "supported" and not self.number_issues


class PointChecker(Protocol):
    async def check(self, passages: str, points: list[Point]) -> dict[str, tuple[str, str]]: ...


def iter_points(node: Any, path: str = "") -> Iterator[Point]:
    """Every object with `labels` and `source_keys`, named by item id or by its JSON path."""
    if isinstance(node, dict):
        labels, keys = node.get("labels"), node.get("source_keys")
        if isinstance(labels, dict) and isinstance(keys, list) and keys:
            name = f"item {node['id']}" if "id" in node else path
            texts = {k: v for k, v in labels.items() if isinstance(v, str)}
            note = node.get("source")
            cited = note if isinstance(note, str) else ""
            yield Point(name, texts, tuple(str(k) for k in keys), cited)
        for key, value in node.items():
            if key not in ("labels", "source_keys"):
                yield from iter_points(value, f"{path}.{key}" if path else str(key))
    elif isinstance(node, list):
        for index, value in enumerate(node):
            part = value.get("key") if isinstance(value, dict) else None
            yield from iter_points(value, f"{path}.{part or index}")


def _words(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z]+", text.lower()) if len(w) >= MIN_WORD_LEN}


def passages_for(text: str, points: list[Point], limit: int) -> str:
    """The whole text when it fits, else the windows sharing the most words with each point,
    in document order, cut to `limit` characters."""
    if len(text) <= limit:
        return text
    windows = [text[i : i + WINDOW_CHARS] for i in range(0, len(text), WINDOW_CHARS)]
    window_words = [_words(w) for w in windows]
    chosen: set[int] = set()
    for point in points:
        wanted = _words(point.labels.get("en", ""))
        scores = sorted(
            range(len(windows)), key=lambda i: len(wanted & window_words[i]), reverse=True
        )
        chosen.update(scores[:WINDOWS_PER_POINT])
    return "\n…\n".join(windows[i] for i in sorted(chosen))[:limit]


def _squash(text: str) -> str:
    return re.sub(r"[\W_]+", "", normalise(text))


def quote_in_source(quote: str, source: str) -> bool:
    """A quote counts only when it is in the source (case, spacing and punctuation aside); a
    quote the model shortened with "…" counts when every part of it is in the source."""
    parts = [_squash(p) for p in re.split(r"…|\.{3}", quote)]
    parts = [p for p in parts if p]
    haystack = _squash(source)
    return bool(parts) and all(p in haystack for p in parts)


def number_issues(point: Point, source_text: str) -> list[str]:
    texts = {lang: point.labels.get(lang) for lang in LANGS}
    return [f"{m.where}: {m.text}" for m in check_output(source_text, texts)]


async def fetch_text(http: httpx.AsyncClient, url: str) -> tuple[str, str | None]:
    """(text, None) or ("", reason). Network problems are reported, never invented around."""
    try:
        response = await http.get(url, headers={"User-Agent": USER_AGENT}, timeout=60)
    except httpx.HTTPError as exc:
        return "", f"{type(exc).__name__}: {exc}"
    if response.status_code >= httpx.codes.BAD_REQUEST:
        return "", f"HTTP {response.status_code}"
    if len(response.content) > MAX_DOCUMENT_BYTES:
        return "", "document too large"
    kind = "pdf" if response.content.startswith(b"%PDF") else "html"
    extraction = extract(response.content, kind)
    if not extraction.text.strip():
        return "", extraction.reason or "no text"
    return extraction.text, None


class AiPointChecker:
    """The Messages API, through the feed adapter's request (same key, model and headers)."""

    def __init__(self, http: httpx.AsyncClient, settings: Settings) -> None:
        from bagmitra_api.feed.ai import AnthropicFeedAi  # noqa: PLC0415 - avoids an import cycle

        self._ai = AnthropicFeedAi(http, settings)
        self._settings = settings

    async def check(self, passages: str, points: list[Point]) -> dict[str, tuple[str, str]]:
        listed = "\n".join(
            f"{p.id}: {p.labels.get('en', '')}"
            + (f" (cited as: {p.cited_as})" if p.cited_as else "")
            for p in points
        )
        answer = await self._ai.ask_json(
            CHECK_PROMPT,
            passages,
            question=f"<points>\n{listed}\n</points>",
            schema=CHECK_SCHEMA,
            max_tokens=self._settings.feed_article_max_tokens,
        )
        out: dict[str, tuple[str, str]] = {}
        for entry in answer.get("points", []):
            if isinstance(entry, dict) and entry.get("verdict") in VERDICTS:
                out[str(entry.get("id"))] = (entry["verdict"], str(entry.get("quote") or ""))
        return out


async def check_cards(
    cards: Mapping[str, Any],
    http: httpx.AsyncClient,
    checker: PointChecker | None,
    *,
    limit: int,
    only: set[str] | None = None,
) -> tuple[list[Result], dict[str, str], dict[str, int]]:
    """Results per point, the sources that could not be read (key -> reason) and the
    characters of text read from each other source (a page that is mostly menu shows here)."""
    sources: Mapping[str, Any] = cards.get("sources", {})
    results = [Result(p) for p in iter_points({k: v for k, v in cards.items() if k != "sources"})]
    texts: dict[str, str] = {}
    failed: dict[str, str] = {}
    for key in sorted({k for r in results for k in r.point.source_keys}):
        if only and key not in only:
            continue
        url = sources.get(key, {}).get("url") if isinstance(sources.get(key), dict) else None
        text, reason = await fetch_text(http, url) if url else ("", "no URL in the cards file")
        if reason:
            failed[key] = reason
            for r in results:
                if key in r.point.source_keys:
                    r.verdicts[key] = ("unreadable", "")
            continue
        texts[key] = text
        if checker is None:
            continue
        mine = [r for r in results if key in r.point.source_keys]
        try:
            answers = await checker.check(
                passages_for(text, [r.point for r in mine], limit), [r.point for r in mine]
            )
        except Exception as exc:  # the model being down is reported, not fatal
            failed[key] = f"AI: {exc}"
            continue
        for r in mine:
            verdict, quote = answers.get(r.point.id, ("not_found", ""))
            if verdict != "not_found" and not quote_in_source(quote, text):
                verdict, quote = "unverified_quote", f"[model: {verdict}] {quote}"
            r.verdicts[key] = (verdict, quote)
    for r in results:
        cited = "\n".join(texts[k] for k in r.point.source_keys if k in texts)
        if cited:
            r.number_issues = number_issues(r.point, cited)
    return results, failed, {k: len(t) for k, t in texts.items()}


def report(
    results: list[Result], failed: Mapping[str, str], read: Mapping[str, int] | None = None
) -> str:
    counts: dict[str, int] = {}
    for r in results:
        counts[r.verdict] = counts.get(r.verdict, 0) + 1
    passed = sum(r.passed for r in results)
    lines = [
        "# Knowledge card check (Q128)",
        "",
        f"Points: {len(results)} · passed: {passed} · "
        + " · ".join(f"{k}: {v}" for k, v in sorted(counts.items())),
        "",
        "| Point | Sources | AI verdict | Numbers not in source | Quote |",
        "|---|---|---|---|---|",
    ]
    for r in sorted(results, key=lambda r: (r.passed, r.verdict, r.point.id)):
        quotes = [q for v, q in r.verdicts.values() if q]
        quote = (quotes[0][:160] + "…") if quotes and len(quotes[0]) > 160 else "".join(quotes[:1])
        cells = [
            r.point.id,
            ", ".join(f"{k}={r.verdicts.get(k, ('-',))[0]}" for k in r.point.source_keys),
            ("✅ " if r.passed else "❌ ") + r.verdict,
            "; ".join(r.number_issues) or "-",
            quote.replace("|", "/").replace("\n", " ") or "-",
        ]
        lines.append("| " + " | ".join(cells) + " |")
    if failed:
        lines += ["", "## Sources not read", ""]
        lines += [f"- {k}: {v}" for k, v in sorted(failed.items())]
    if read:
        lines += ["", "## Characters read per source", ""]
        lines += [" · ".join(f"{k}={v}" for k, v in sorted(read.items()))]
    return "\n".join(lines) + "\n"


async def main(argv: list[str]) -> int:  # pragma: no cover - thin CLI wrapper
    raw = sys.stdin.read() if argv[0] == "-" else Path(argv[0]).read_text(encoding="utf-8")
    cards = json.loads(raw)
    only = set(argv[argv.index("--only") + 1 :]) if "--only" in argv else None
    settings = get_settings()
    async with httpx.AsyncClient(follow_redirects=True) as http:
        checker = (
            AiPointChecker(http, settings) if settings.feed_ai_api_key.get_secret_value() else None
        )
        if checker is None:
            print("FEED_AI_API_KEY is not set: number check only", file=sys.stderr)
        results, failed, read = await check_cards(
            cards, http, checker, limit=settings.feed_ai_max_source_chars, only=only
        )
    print(report(results, failed, read))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(asyncio.run(main(sys.argv[1:])))
