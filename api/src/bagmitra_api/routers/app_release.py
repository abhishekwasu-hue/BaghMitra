"""App update path (audit BG-06). `GET /v1/app/version` tells the app which version is the
latest and which is the oldest still allowed; `GET /app` hands out the latest APK. Both are
public: the app asks before sign-in, and a grower downloads the APK from a phone browser.

Only the fixed file APP_DOWNLOAD_DIR/bagmitra.apk is served; no part of the request is used
to build a path.
"""

from __future__ import annotations

from pathlib import Path
from typing import Annotated

from fastapi import APIRouter, Depends, Request, Response
from fastapi.responses import FileResponse, PlainTextResponse
from pydantic import BaseModel

from bagmitra_api.core.settings import Settings, get_settings

router = APIRouter(tags=["app"])

APK_FILE = "bagmitra.apk"
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
    return AppVersionResponse(
        latest_version_code=settings.app_latest_version_code,
        latest_version_name=settings.app_latest_version_name,
        min_version_code=settings.app_min_version_code,
        download_url=settings.app_download_url or str(request.url_for("download_apk")),
    )


@router.api_route("/app", methods=["GET", "HEAD"], include_in_schema=False)
async def download_apk(settings: Annotated[Settings, Depends(get_settings)]) -> Response:
    path = Path(settings.app_download_dir) / APK_FILE
    if not path.is_file():
        return PlainTextResponse(_NOT_AVAILABLE, status_code=404)
    return FileResponse(
        path,
        media_type=APK_MEDIA_TYPE,
        filename=APK_FILE,
        headers={"Cache-Control": "no-cache", "X-Content-Type-Options": "nosniff"},
    )
