"""Offline Q&A build (owner 2026-11-12, Q144). The model is reached only through
httpx.MockTransport (nothing leaves the test). Covered: the Message Batches flow with prompt
caching, resume from the work file (no second call), a batch an earlier run submitted, the
concurrent mode with its refusal fallback and retry, answers dropped by the knowledge-article
check (and counted by reason), the cost summary, the seed made of card texts only, the search
keys shared with the app, and the workflow file."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

import httpx
import pytest
import yaml  # type: ignore[import-untyped]  # PyYAML comes with bandit (dev extra)

from bagmitra_api.bahar.seed import stage_template_seeds
from bagmitra_api.feed.knowledge import practice_cards
from bagmitra_api.kb import qa_text
from bagmitra_api.kb.qa_api import ModelClient, Usage
from bagmitra_api.kb.qa_build import (
    ANSWERS_PROMPT,
    PARAPHRASE_PROMPT,
    QUESTIONS_PROMPT,
    STORED_NOTE,
    Builder,
    BuildReport,
    QaTopic,
    WorkFile,
    asset,
    build_seed,
    card_topics,
    check_answer,
    dedupe,
    fco_topic,
    finalise_asset,
    howto_topics,
    is_referral,
    label_topics,
    read_asset,
    report_markdown,
    strip_referral_tail,
    write_asset,
)

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "app"
ASSET = APP / "assets" / "config" / "qa_kb.json.gz"
STRONG, CHEAP = "claude-sonnet-5-5", "claude-haiku-5-5"
SOURCE = (
    '<cards>\n- Hang yellow sticky traps, 30 per acre.\n</cards>\n<source key="S1" title="NHB">'
    "\nHang yellow sticky traps at 30 per acre from June. Watch every new flush.\n</source>"
)
TOPIC = QaTopic(
    key="section:psylla",
    about="Psylla card",
    text=SOURCE,
    sources={"S1": ("NHB Citrus: Pests", "https://nhb.gov.in/pests.pdf")},
    points=1,
    section="psylla",
)
QUESTIONS = [
    {
        "mr": "सायलासाठी किती सापळे लावावेत?",
        "hi": "सिल्ला के लिए कितने ट्रैप?",
        "en": "How many traps for psylla?",
    },
    {"mr": "नवती कशी तपासावी?", "hi": "नई फुटान कैसे जाँचें?", "en": "How do I check the new flush?"},
    {
        "mr": "सायलासाठी किती सापळे लावायचे?",
        "hi": "सिल्ला के लिए ट्रैप कितने?",
        "en": "How many traps for psylla ?",
    },
    {"mr": "फवारणी किती वेळा?", "hi": "छिड़काव कितनी बार?", "en": "How often do I spray?"},
]
GOOD = {
    "mr": [
        "एकरी ३० पिवळे चिकट सापळे लावा.",
        "जूनपासून लावा.",
        "नवती तपासा.",
        "शंका असल्यास KVK ला विचारा.",
    ],
    "hi": ["प्रति एकड़ 30 पीले ट्रैप लगाएँ।", "जून से लगाएँ।", "नई फुटान देखें।", "शंका हो तो KVK से पूछें।"],
    "en": [
        "Hang 30 yellow sticky traps per acre.",
        "Start in June.",
        "Watch every new flush.",
        "Ask the KVK when unsure.",
    ],
}


def message(model: str, payload: dict[str, Any], **usage: int) -> dict[str, Any]:
    return {
        "model": model,
        "stop_reason": "end_turn",
        "content": [{"type": "text", "text": json.dumps(payload, ensure_ascii=False)}],
        "usage": {"input_tokens": 1000, "output_tokens": 500, **usage},
    }


def answer_for(params: dict[str, Any]) -> dict[str, Any]:
    """The fake model: drafts QUESTIONS, answers them (one with a number not in the source,
    one not answerable) and paraphrases."""
    system = params["system"]
    content = params["messages"][0]["content"]
    if system.startswith(QUESTIONS_PROMPT[:40]):
        return message(STRONG, {"questions": QUESTIONS}, cache_creation_input_tokens=2000)
    asked = content[-1]["text"]
    ids = re.findall(r"^(q[0-9a-f]+):", asked, re.MULTILINE)
    if system == ANSWERS_PROMPT:
        out = []
        for qid in ids:
            line = next(x for x in asked.splitlines() if x.startswith(qid))
            if "spray" in line:
                out.append(
                    {
                        "id": qid,
                        "answerable": False,
                        "mr": [],
                        "hi": [],
                        "en": [],
                        "source_keys": [],
                    }
                )
            elif "flush" in line:
                bad = {
                    k: [*v[:3], "७ दिवसांनी पुन्हा." if k == "mr" else "Repeat after 7 days."]
                    for k, v in GOOD.items()
                }
                out.append({"id": qid, "answerable": True, **bad, "source_keys": ["S1"]})
            else:
                out.append({"id": qid, "answerable": True, **GOOD, "source_keys": ["S1", "X9"]})
        return message(STRONG, {"answers": out}, cache_read_input_tokens=3000)
    assert system == PARAPHRASE_PROMPT
    items = [
        {"id": i, "paraphrases": ["santra sayla sapale kiti", "सायला सापळे", "सिल्ला ट्रैप"]}
        for i in ids
    ]
    return message(CHEAP, {"items": items})


class FakeApi:
    """The Messages and Message Batches endpoints over MockTransport."""

    def __init__(self, *, fail_first_post: bool = False) -> None:
        self.calls: list[tuple[str, str]] = []
        self.batches: dict[str, list[dict[str, Any]]] = {}
        self.posts: list[httpx.Request] = []
        self.fail_first_post = fail_first_post

    def __call__(self, request: httpx.Request) -> httpx.Response:
        path = request.url.path
        self.calls.append((request.method, path))
        assert request.headers["anthropic-version"] == "2026-10-21"
        assert request.headers["x-api-key"] == "test-key"
        if request.method == "POST" and path == "/v1/messages/batches":
            body = json.loads(request.content)
            batch_id = f"msgbatch_{len(self.batches) + 1}"
            self.batches[batch_id] = body["requests"]
            return httpx.Response(200, json={"id": batch_id, "processing_status": "in_progress"})
        if m := re.fullmatch(r"/v1/messages/batches/(\w+)", path):
            return httpx.Response(
                200,
                json={
                    "id": m[1],
                    "processing_status": "ended",
                    "results_url": f"https://api.test/v1/messages/batches/{m[1]}/results",
                },
            )
        if m := re.fullmatch(r"/v1/messages/batches/(\w+)/results", path):
            lines = [
                json.dumps(
                    {
                        "custom_id": r["custom_id"],
                        "result": {"type": "succeeded", "message": answer_for(r["params"])},
                    },
                    ensure_ascii=False,
                )
                for r in self.batches[m[1]]
            ]
            return httpx.Response(200, text="\n".join(lines))
        if request.method == "POST" and path == "/v1/messages":
            self.posts.append(request)
            if self.fail_first_post and len(self.posts) == 1:
                return httpx.Response(429, json={"error": "rate"})
            return httpx.Response(200, json=answer_for(json.loads(request.content)))
        return httpx.Response(404)


def builder(http: httpx.AsyncClient, work: Path, mode: str = "batch") -> Builder:
    client = ModelClient(
        http,
        api_key="test-key",
        base_url="https://api.test",
        mode=mode,
        poll_seconds=0,
        retry_seconds=0,
    )
    return Builder(
        client,
        WorkFile(work / "qa_work.jsonl"),
        strong_model=STRONG,
        cheap_model=CHEAP,
        max_tokens=16000,
    )


async def test_batch_build_checks_drops_and_costs(tmp_path: Path) -> None:
    api = FakeApi()
    async with httpx.AsyncClient(transport=httpx.MockTransport(api)) as http:
        b = builder(http, tmp_path)
        entries = await b.build([TOPIC])
    # Three batches: questions, answers, paraphrases; each read back once.
    assert [c for c in api.calls if c[0] == "POST"] == [("POST", "/v1/messages/batches")] * 3
    first = next(iter(api.batches.values()))[0]["params"]
    doc = first["messages"][0]["content"][0]
    assert doc["cache_control"] == {"type": "ephemeral"}
    assert "<document>" in doc["text"]
    assert SOURCE in doc["text"]
    assert first["model"] == STRONG
    assert first["output_config"]["format"]["type"] == "json_schema"
    paraphrase = list(api.batches.values())[2][0]["params"]
    assert paraphrase["model"] == CHEAP
    assert paraphrase["output_config"]["effort"] == "low"
    # Duplicate removed; "flush" has a number not in the source; "spray" not answerable.
    r = b.report
    assert (r.questions_drafted, r.duplicates_removed) == (4, 1)
    assert r.answers_dropped == {"number": 1, "not_answerable": 1}
    assert len(entries) == r.answers_kept == 1
    e = entries[0]
    # The closing "ask the KVK" line is removed in all three languages.
    assert e["a"] == {lang: lines[:-1] for lang, lines in GOOD.items()}
    assert r.referral_lines_removed == 1
    assert e["sec"] == "psylla"
    assert e["s"] == ["S1"]  # an unknown key the model named is not kept
    assert len(e["p"]) == 3
    usage = b.usage()
    row = usage.rows[(STRONG, True)]
    assert row["requests"] == 2
    assert row["cache_read_input_tokens"] == 3000
    # (2000 + 2000 input, 1000 output, 2000 write, 3000 read) on Sonnet, (1000, 500) on Haiku,
    # every one at half price in a batch.
    sonnet = (2000 * 2 + 1000 * 10 + 2000 * 2.5 + 3000 * 0.1) / 1e6
    haiku = (1000 * 0.1 + 500 * 0.5) / 1e6
    assert usage.dollars() == pytest.approx((sonnet + haiku) / 2, abs=1e-4)
    text = report_markdown(r, usage, "batch")
    assert "not_answerable 1" in text
    assert "number 1" in text
    assert "Estimated cost" in text


async def test_resume_makes_no_new_call(tmp_path: Path) -> None:
    async with httpx.AsyncClient(transport=httpx.MockTransport(FakeApi())) as http:
        first = await builder(http, tmp_path).build([TOPIC])
    again = FakeApi()
    async with httpx.AsyncClient(transport=httpx.MockTransport(again)) as http:
        b = builder(http, tmp_path)
        second = await b.build([TOPIC])
    assert again.calls == []
    assert second == first
    assert b.usage().rows[(STRONG, True)]["requests"] == 2  # cost of the first run kept


async def test_batch_of_an_earlier_run_is_collected_not_resent(tmp_path: Path) -> None:
    api = FakeApi()
    async with httpx.AsyncClient(transport=httpx.MockTransport(api)) as http:
        b = builder(http, tmp_path)
        await b.questions([TOPIC])
    # The run "stopped" right after submitting: forget the result, keep the batch record.
    work = tmp_path / "qa_work.jsonl"
    lines = [json.loads(x) for x in work.read_text("utf-8").splitlines()]
    kept = [x for x in lines if x["kind"] not in ("questions", "usage")]
    for x in kept:
        x["status"] = "submitted"
    work.write_text("".join(json.dumps(x, ensure_ascii=False) + "\n" for x in kept), "utf-8")
    api.calls.clear()
    async with httpx.AsyncClient(transport=httpx.MockTransport(api)) as http:
        got = await builder(http, tmp_path).questions([TOPIC])
    assert ("POST", "/v1/messages/batches") not in api.calls
    assert ("GET", "/v1/messages/batches/msgbatch_1/results") in api.calls
    assert len(got[TOPIC.key]) == 4


async def test_concurrent_mode_retries_and_uses_fallback(tmp_path: Path) -> None:
    api = FakeApi(fail_first_post=True)
    async with httpx.AsyncClient(transport=httpx.MockTransport(api)) as http:
        b = builder(http, tmp_path, mode="concurrent")
        entries = await b.build([TOPIC])
    assert len(entries) == 1
    strong = [p for p in api.posts if json.loads(p.content)["model"] == STRONG]
    assert strong[0].headers["anthropic-beta"] == "server-side-fallback-2026-07-01"
    assert json.loads(strong[0].content)["fallbacks"] == "default"
    cheap = [p for p in api.posts if json.loads(p.content)["model"] == CHEAP]
    assert "anthropic-beta" not in cheap[0].headers
    assert len(api.posts) == 4  # questions (429, then 200), one answer group, one paraphrase
    assert (STRONG, False) in b.usage().rows


async def test_failed_reply_is_retried_on_the_next_run(tmp_path: Path) -> None:
    def refuse(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"stop_reason": "refusal", "content": [], "model": STRONG})

    async with httpx.AsyncClient(transport=httpx.MockTransport(refuse)) as http:
        b = builder(http, tmp_path, mode="concurrent")
        assert await b.build([TOPIC]) == []
    assert b.report.errors == {"questions: model declined the request": 1}
    async with httpx.AsyncClient(transport=httpx.MockTransport(FakeApi())) as http:
        assert len(await builder(http, tmp_path, mode="concurrent").build([TOPIC])) == 1


def test_check_answer_reasons() -> None:
    q = {"mr": "सापळे?", "hi": "ट्रैप?", "en": "Traps?"}
    assert check_answer(SOURCE, q, {"answerable": True, **GOOD}) == []
    short = {k: v[:2] for k, v in GOOD.items()}
    assert check_answer(SOURCE, q, {"answerable": True, **short}) == ["length"]
    named = {k: [*v, "Captan"] for k, v in GOOD.items()}
    assert check_answer(SOURCE, q, {"answerable": True, **named}) == ["product"]
    scary = {k: [*v, "This is a disaster."] for k, v in GOOD.items()}
    assert check_answer(SOURCE, q, {"answerable": True, **scary}) == ["alarm_word"]
    phone = {k: [*v, "Call 9876543210."] for k, v in GOOD.items()}
    assert "contact" in check_answer(SOURCE, q, {"answerable": True, **phone})
    assert check_answer(SOURCE, q, {"answerable": False}) == ["not_answerable"]


def test_dedupe_keeps_the_first() -> None:
    kept, removed = dedupe(QUESTIONS)
    assert removed == 1
    assert kept[0] is QUESTIONS[0]
    assert QUESTIONS[2] not in kept


async def test_card_topics_use_checked_points_and_their_sources() -> None:
    cards = practice_cards()

    async def fetch(url: str) -> tuple[str, str | None]:
        if "nhb.gov.in/pdf/fruits/citrus/cit008" in url:
            return "Citrus Psylla. Nymphs suck sap from buds and tender leaves.", None
        return "", "HTTP 403"

    topics = await card_topics(cards, fetch, 60_000, stage_template_seeds())
    assert topics, "a readable source gives at least one topic"
    for t in topics:
        assert set(t.sources) <= {"C08"}
        assert "agrowon" not in t.text.lower()


def test_other_topics_are_built_from_bundled_data() -> None:
    labels = label_topics()
    assert len(labels) == 4
    assert all("waiting period" in t.about for t in labels)
    assert all(t.sources[k][1].startswith("https://") for t in labels for k in t.sources)
    fco = fco_topic()
    assert "Zinc Sulphate Heptahydrate" in fco.text
    assert "AS DATA ONLY" in fco.about
    howtos = {t.key: t for t in howto_topics(APP)}
    assert set(howtos) == {"howto:spray", "howto:bill", "howto:sale_lot", "howto:photo_check"}
    assert "फवारणी" in howtos["howto:spray"].text
    assert "बिलाचा फोटो" in howtos["howto:bill"].text
    assert howtos["howto:photo_check"].sources == {"app": ("BagMitra ॲप", "")}


def test_asset_round_trip_and_size(tmp_path: Path) -> None:
    entry = {
        "id": "q1",
        "t": "x",
        "sec": None,
        "q": dict.fromkeys(("mr", "hi", "en"), "फळगळ"),
        "a": {"mr": ["अ"], "hi": ["अ"], "en": ["a"]},
        "s": ["S1"],
        "p": ["falgal"],
    }
    data = asset([entry], TOPIC.sources, "generated")
    assert data["note"] == STORED_NOTE
    assert data["src"] == {"S1": {"t": "NHB Citrus: Pests", "u": "https://nhb.gov.in/pests.pdf"}}
    assert "~plgl" in data["entries"][0]["k"]
    raw, packed = write_asset(data, tmp_path / "a.json.gz")
    assert packed < raw
    first = (tmp_path / "a.json.gz").read_bytes()
    write_asset(data, tmp_path / "a.json.gz")
    assert (tmp_path / "a.json.gz").read_bytes() == first  # no timestamp in the gzip
    assert read_asset(tmp_path / "a.json.gz") == data


def _card_texts(cards: dict[str, Any], lang: str) -> set[str]:
    out: set[str] = set()

    def walk(node: Any) -> None:
        if isinstance(node, dict):
            labels = node.get("labels")
            if isinstance(labels, dict) and isinstance(labels.get(lang), str):
                out.add(labels[lang].strip())
            for v in node.values():
                walk(v)
        elif isinstance(node, list):
            for v in node:
                walk(v)

    walk(cards)
    return out


def test_seed_is_card_text_only() -> None:
    """The shipped asset carries the seed exactly as the seed builder makes it, and every seed
    answer line is a checked card text of the same language, word for word. The app's test
    fixture is the seed asset itself."""
    data = read_asset(ASSET)
    cards = json.loads((APP / "assets" / "config" / "practice_cards.json").read_text("utf-8"))
    seed = build_seed(cards)
    assert read_asset(APP / "test" / "fixtures" / "qa_kb_seed.json.gz") == seed
    shipped = {e["id"]: e for e in data["entries"] if e["id"].startswith("seed-")}
    assert list(shipped.values()) == seed["entries"]
    assert 30 <= len(shipped) <= 60
    for lang in ("mr", "hi", "en"):
        texts = _card_texts(cards, lang)
        for e in seed["entries"]:
            assert e["a"][lang], e["id"]
            for line in e["a"][lang]:
                assert line in texts, (e["id"], lang, line)
    for e in seed["entries"]:
        assert e["s"]
        assert all(data["src"][k]["u"].startswith("https://") for k in e["s"])
        assert all(cards["sources"][k]["publisher"] != "Agrowon" for k in e["s"])


def test_shipped_asset_shape() -> None:
    data = read_asset(ASSET)
    assert data["version"] == 1
    assert data["kind"] in ("seed", "generated")
    for e in data["entries"]:
        assert set(e) >= {"id", "q", "a", "s", "k"}
        assert all(k in data["src"] for k in e["s"])
        assert e["k"] == qa_text.index_keys(*(e["q"][lang] for lang in ("mr", "hi", "en")), *e["p"])


def test_search_keys_match_the_app_fixture() -> None:
    """The app normalises the farmer's question with the same rules (Dart test reads the same
    fixture)."""
    cases = json.loads((APP / "test" / "fixtures" / "qa_normalise_cases.json").read_text("utf-8"))
    assert len(cases) >= 20
    for case in cases:
        assert qa_text.words(case["text"]) == case["words"], case["text"]
        assert qa_text.index_keys(case["text"]) == case["keys"], case["text"]


def test_word_lists_match_the_app() -> None:
    dart = (APP / "lib" / "features" / "ask" / "domain" / "qa_text.dart").read_text("utf-8")

    def listed(name: str) -> set[str]:
        block = re.search(rf"{name} = <String>\{{(.*?)\}};", dart, re.DOTALL)
        assert block, name
        return set(re.findall(r"'([^']+)'", block.group(1)))

    assert listed("qaStopwords") == set(qa_text.STOPWORDS)
    assert listed("qaSuffixes") == set(qa_text.SUFFIXES)


async def test_several_batches_are_all_submitted_then_collected(tmp_path: Path) -> None:
    api = FakeApi()
    other = QaTopic("section:mites", "Mites card", SOURCE, TOPIC.sources, 1, "mites")
    async with httpx.AsyncClient(transport=httpx.MockTransport(api)) as http:
        client = ModelClient(
            http, api_key="test-key", base_url="https://api.test", poll_seconds=0, batch_max=1
        )
        b = Builder(
            client,
            WorkFile(tmp_path / "w.jsonl"),
            strong_model=STRONG,
            cheap_model=CHEAP,
            max_tokens=16000,
        )
        got = await b.questions([TOPIC, other])
    posts = [i for i, c in enumerate(api.calls) if c == ("POST", "/v1/messages/batches")]
    reads = [i for i, c in enumerate(api.calls) if c[1].endswith("/results")]
    assert posts == [0, 1]
    assert min(reads) > max(posts)
    assert set(got) == {TOPIC.key, other.key}


def test_usage_without_a_price_is_unpriced() -> None:
    u = Usage()
    u.add("claude-unknown", False, {"input_tokens": 10})
    assert u.dollars() is None


def test_workflow_file() -> None:
    wf = yaml.safe_load((ROOT / ".github" / "workflows" / "qa-build.yml").read_text("utf-8"))
    triggers = wf.get("on", wf.get(True))
    assert "workflow_dispatch" in triggers
    assert wf["permissions"] == {"contents": "write", "pull-requests": "write"}
    job = wf["jobs"]["build"]
    assert job["env"] == {
        "ANTHROPIC_API_KEY": "${{ secrets.ANTHROPIC_API_KEY }}",
        "FEED_AI_API_KEY": "${{ secrets.FEED_AI_API_KEY }}",
    }
    steps = job["steps"]
    text = json.dumps(steps)
    assert "bagmitra_api.kb.qa_build build" in text
    assert "qa-data-" in text
    assert "gh pr create" in text
    # The first step names the secret that is set (never its value) and fails without one.
    which = steps[0]
    assert which["name"].startswith("Which API key")
    assert "exit 1" in which["run"]
    assert "::error::" in which["run"]
    assert "echo $ANTHROPIC_API_KEY" not in which["run"]
    assert "echo $FEED_AI_API_KEY" not in which["run"]


def test_report_lists_skipped_schemes() -> None:
    r = BuildReport(skipped=["Government schemes: run with --schemes"])
    assert "Government schemes" in report_markdown(r, Usage(), "batch")


def test_closing_referral_lines() -> None:
    """Owner: closing "ask the KVK / expert / officer" lines are unnecessary warnings."""
    referral = {
        "mr": "अधिक माहितीसाठी आपल्या KVK ला विचारा.",
        "hi": "अधिक जानकारी के लिए अपने KVK से पूछें।",
        "en": "For more details, please check the label and ask your KVK.",
    }
    answer = {lang: [*GOOD[lang][:3], referral[lang]] for lang in GOOD}
    stripped, removed = strip_referral_tail(answer)
    assert removed
    assert stripped == {lang: GOOD[lang][:3] for lang in GOOD}
    # A line with a fact or a number stays, and so does every line inside the answer.
    for en in (
        "Only a lab test confirms greening; if in doubt, ask your KVK.",
        "Ask the KVK; the label prints a waiting period of 15 days.",
        "Action levels are not published in the sources read; ask your KVK.",
    ):
        assert not is_referral("en", en), en
    assert not is_referral("mr", "PHI १५ दिवस; KVK ला विचारा.")
    kept, removed = strip_referral_tail(
        {**answer, "en": [*GOOD["en"][:3], "Harvest in dry weather."]}
    )
    assert not removed
    assert kept["mr"][-1] == referral["mr"]
    # Only when the last line refers in ALL three languages; a one-line answer stays.
    assert not strip_referral_tail({lang: [referral[lang]] for lang in GOOD})[1]
    assert is_referral("en", "To be sure for your orchard, ask the KVK.")
    assert is_referral("en", "Ask your KVK for more details.")
    assert is_referral("hi", "शंका हो तो अपने कृषि विज्ञान केंद्र (KVK) से पूछें।")


def test_answer_prompt_asks_for_no_closing_referral() -> None:
    assert "Do not end an answer with a line that only sends the farmer to the KVK" in (
        ANSWERS_PROMPT
    )
    assert "have the full directions." not in ANSWERS_PROMPT.split("Do not end")[0]


def test_finalise_strips_once_and_keeps_the_seed() -> None:
    cards = practice_cards()
    seed_q = build_seed(cards)["entries"][0]["q"]
    referral = {"mr": "KVK ला विचारा.", "hi": "KVK से पूछें।", "en": "Ask your KVK."}
    raw = {
        "src": {"S1": {"t": "NHB", "u": "https://nhb.gov.in/a.pdf"}},
        "entries": [
            {"id": "q1", "t": "section:psylla", "sec": "psylla", "q": QUESTIONS[0], "s": ["S1"],
             "p": [], "a": {lang: [*GOOD[lang], referral[lang]] for lang in GOOD}},
            # The same question as a seed entry: the seed (card text) is kept instead.
            {"id": "q2", "t": "section:psylla", "sec": "psylla", "q": dict(seed_q), "s": ["S1"],
             "p": [], "a": {lang: lines[:3] for lang, lines in GOOD.items()}},
        ],
    }  # fmt: skip
    data, counts = finalise_asset(raw, cards)
    assert counts == {"referral_lines_removed": 1, "duplicates_of_seed": 1}
    ids = [e["id"] for e in data["entries"]]
    assert ids[0].startswith("seed-")
    assert "q1" in ids
    assert "q2" not in ids
    assert data["tidy"] is True
    q1 = next(e for e in data["entries"] if e["id"] == "q1")
    assert q1["a"]["en"] == GOOD["en"]
    again, counts = finalise_asset(data, cards)
    assert counts == {"referral_lines_removed": 0, "duplicates_of_seed": 0}
    assert again == data
