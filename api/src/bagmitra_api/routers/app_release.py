"""App update path (audit BG-06). `GET /v1/app/version` tells the app which version is the
latest and which is the oldest still allowed; `GET /app` hands out the latest Release APK and
`GET /app/test` the latest Test APK (audit H1: two files, a Test APK cannot install a Release
APK). All are public: the app asks before sign-in, and a grower downloads the APK from a phone
browser.

Only the fixed files APP_DOWNLOAD_DIR/bagmitra.apk and bagmitra-test.apk are served; no part
of the request is used to build a path.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Annotated

from fastapi import APIRouter, Depends, Request, Response
from fastapi.responses import FileResponse, PlainTextResponse
from pydantic import BaseModel

from bagmitra_api.core.settings import Settings, get_settings

router = APIRouter(tags=["app"])

APK_FILE = "bagmitra.apk"
TEST_APK_FILE = "bagmitra-test.apk"
RELEASE_FILE = "release.json"
APK_MEDIA_TYPE = "application/vnd.android.package-archive"
_NOT_AVAILABLE = (
    "बागमित्र ॲप अजून इथे उपलब्ध नाही. थोड्या वेळाने पुन्हा पाहा.\n"
    "The BagMitra app is not available here yet. Please try again later.\n"
)


class AppVersionResponse(BaseModel):
    latest_version_code: int
    latest_version_name: str
    min_version_code: int
    download_url: str


@router.get("/v1/app/version", operation_id="app_version")
async def app_version(
    request: Request,
    response: Response,
    settings: Annotated[Settings, Depends(get_settings)],
) -> AppVersionResponse:
    """Latest and minimum app version codes (0 = not set) and where to download the APK."""
    response.headers["Cache-Control"] = "no-cache"
    code, name = settings.app_latest_version_code, settings.app_latest_version_name
    if code == 0:
        code, name = _mirrored_release(Path(settings.app_download_dir))
    return AppVersionResponse(
        latest_version_code=code,
        latest_version_name=name,
        min_version_code=settings.app_min_version_code,
        download_url=settings.app_download_url or str(request.url_for("download_apk")),
    )


def _mirrored_release(folder: Path) -> tuple[int, str]:
    """The Release APK the VPS mirror placed (deploy/fetch_test_apk.sh writes release.json
    beside it); (0, "") when there is none or it cannot be read."""
    try:
        data = json.loads((folder / RELEASE_FILE).read_text("utf-8"))
        return int(data["code"]), str(data["name"])
    except (OSError, ValueError, KeyError, TypeError):
        return 0, ""


@router.api_route("/app", methods=["GET", "HEAD"], include_in_schema=False)
async def download_apk(settings: Annotated[Settings, Depends(get_settings)]) -> Response:
    return _serve(Path(settings.app_download_dir), APK_FILE)


@router.api_route("/app/test", methods=["GET", "HEAD"], include_in_schema=False)
async def download_test_apk(settings: Annotated[Settings, Depends(get_settings)]) -> Response:
    return _serve(Path(settings.app_download_dir), TEST_APK_FILE)


def _serve(folder: Path, name: str) -> Response:
    path = folder / name
    if not path.is_file():
        return PlainTextResponse(_NOT_AVAILABLE, status_code=404)
    return FileResponse(
        path,
        media_type=APK_MEDIA_TYPE,
        filename=name,
        headers={"Cache-Control": "no-cache", "X-Content-Type-Options": "nosniff"},
    )
