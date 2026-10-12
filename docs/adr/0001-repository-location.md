# ADR 0001 — Repository location

Status: Accepted · 2026-10-12

## Context
The spec asks for a dedicated repository. M0 was first built in a self-contained `bagmitra/`
folder of the owner's `trade` repository (the only one the build session could reach), and
reviewed there as PR abhishekwasu-hue/trade#301.

## Decision
BaghMitra lives in its own repository, `abhishekwasu-hue/BaghMitra`. The `bagmitra/` history was
moved with `git subtree split --prefix=bagmitra` and merged into this repository's `main`, so
every commit is preserved. CI workflows and the PR template moved to this repository's
`.github/` with paths relative to the root.

## Consequences
The `trade` repository no longer carries BaghMitra code. The product name
(BaghMitra) is set in `product.env`; internal identifiers keep `bagmitra` (OPEN_QUESTIONS Q9).
