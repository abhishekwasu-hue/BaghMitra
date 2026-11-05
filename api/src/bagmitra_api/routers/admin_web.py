"""The admin web (Flutter web build of `app/lib/main_admin.dart`) served at `/admin/` (OPS-02).

Same origin as the API, so the browser needs no CORS. The page only shows the sign-in and the
sections; every admin call still goes to the role-checked `/v1/admin/...` endpoints. Files come
from ADMIN_WEB_DIR (deploy.sh unpacks the CI build there); when it is unset, empty or has no
`index.html`, `/admin/` answers a plain 404. Not part of the OpenAPI contract.

`/admin/config.json` hands the page the Supabase project URL and its public anon key at
runtime, so the build carries no environment values. Both are public by design (they are in
every app build too); nothing else from the settings is read.
"""

from __future__ import annotations

import os
from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from starlette.responses import Response
from starlette.staticfiles import StaticFiles
from starlette.types import Scope

from bagmitra_api.core.errors import ApiError
from bagmitra_api.core.settings import Settings, get_settings

MOUNT_PATH = "/admin"

router = APIRouter(include_in_schema=False)

# Flutter's file names carry no content hash, so the browser revalidates every file (ETag);
# the page must not be framed by another site. Scripts are not restricted further: the
# Flutter bootstrap, its wasm renderer and the Supabase client need them.
HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "no-referrer",
    "Content-Security-Policy": "frame-ancestors 'none'",
    "X-Frame-Options": "DENY",
    "Cache-Control": "no-cache",
}


@router.get(f"{MOUNT_PATH}/config.json")
async def admin_web_config(settings: Annotated[Settings, Depends(get_settings)]) -> JSONResponse:
    url = settings.admin_web_supabase_url.strip()
    key = settings.admin_web_supabase_anon_key.strip()
    if not url or not key:
        raise ApiError(404, "not_configured", "the admin web is not configured")
    return JSONResponse(
        {"supabase_url": url, "supabase_anon_key": key},
        headers={**HEADERS, "Cache-Control": "no-store"},
    )


class AdminWebFiles(StaticFiles):
    """StaticFiles that tolerates a missing folder (404 instead of a server error), so the API
    starts and runs before the first admin build is unpacked, and adds the headers above."""

    async def check_config(self) -> None:
        return None

    def lookup_path(self, path: str) -> tuple[str, os.stat_result | None]:
        if not self.directory or not os.path.isdir(self.directory):
            return "", None
        return super().lookup_path(path)

    def file_response(
        self,
        full_path: str | os.PathLike[str],
        stat_result: os.stat_result,
        scope: Scope,
        status_code: int = 200,
    ) -> Response:
        response = super().file_response(full_path, stat_result, scope, status_code)
        response.headers.update(HEADERS)
        return response


def admin_web_files(settings: Settings) -> AdminWebFiles | None:
    """The `/admin` mount, or None when ADMIN_WEB_DIR is unset (then `/admin/` is a 404)."""
    directory = settings.admin_web_dir.strip()
    if not directory:
        return None
    return AdminWebFiles(directory=directory, html=True, check_dir=False)
