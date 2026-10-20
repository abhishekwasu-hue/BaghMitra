# Git and pull-request habits

- **Identifiers come from tools, never from memory.** Commit SHAs, PR numbers, run ids and
  branch names are copied from `git`, the GitHub tools or CI output. A merge with an expected
  head SHA uses the full 40 characters from `git rev-parse origin/<branch>` (a SHA typed from
  memory is rejected with "Head branch was modified"; a short SHA is rejected too).
- One feature per PR, ≤ 400 production lines, tests first, self-review checklist in the
  description. Merge your own PR once every check is green; docs-only PRs run no checks.
- A PR that adds a dependency says so in its description, with what it pulls in.
- Never skip, disable or quarantine a test to get green; never push an empty commit to kick CI.
- Before pushing app changes run: `dart format --output=none --set-exit-if-changed lib test tool`,
  `flutter analyze`, `flutter test --coverage`, `dart run tool/coverage_gate.dart 80`.
  Before pushing API changes run: `ruff check .`, `ruff format --check .`, `mypy src tests alembic`,
  `bandit -q -c pyproject.toml -r src`, `pytest`. Regenerate goldens only after looking at them.
