from __future__ import annotations

import fnmatch
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_every_data_file_under_src_ships_in_the_package() -> None:
    """The VPS image installs the package (`pip install .`); a data file read with
    importlib.resources but missing from package-data only fails there."""
    config = tomllib.loads((ROOT / "pyproject.toml").read_text("utf-8"))
    package_data: dict[str, list[str]] = config["tool"]["setuptools"]["package-data"]
    src = ROOT / "src"
    missing = []
    for path in sorted(src.rglob("*")):
        if path.suffix not in {".json", ".csv", ".yaml"} or "__pycache__" in path.parts:
            continue
        package = ".".join(path.parent.relative_to(src).parts)
        patterns = package_data.get(package, [])
        if not any(fnmatch.fnmatch(path.name, p) for p in patterns):
            missing.append(str(path.relative_to(src)))
    assert missing == []
