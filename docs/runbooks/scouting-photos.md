# Scouting photos: optional server backup (OPEN_QUESTIONS Q34)

By default a scouting photo stays only on the phone. With the three settings below the API
hands out **signed URLs** for a private Supabase Storage bucket: the phone uploads the photo
straight to the bucket and the grower's other phones download it with a short-lived link.
Without them both photo endpoints answer `503 photo_backup_not_configured` and the app
quietly keeps photos local until its next start. Nothing about this goes in git.

## 1. Create the bucket (Supabase dashboard, once)

1. Storage -> New bucket -> name `scouting-photos`, **Public: off** (private).
2. Bucket settings: file size limit **2 MB**, allowed MIME types **`image/jpeg`**. The app
   already resizes to 1280 px / quality 70 (typically 150-400 KB); the API also refuses
   uploads it is told are larger than `PHOTO_MAX_BYTES` (2 MiB).
3. No storage RLS policies are needed: phones never talk to Storage with their own token,
   only through URLs the API signs after checking the record is theirs.

## 2. Set the secrets on the VPS

In `deploy/.env` (chmod 600, never in git, never in chat):

```
PHOTO_STORAGE_URL=https://<project-ref>.supabase.co
PHOTO_STORAGE_BUCKET=scouting-photos
PHOTO_STORAGE_SERVICE_KEY=<service_role key from Project Settings -> API>
```

The service key is a `SecretStr`: it is sent only to Supabase and never logged or returned.
Then redeploy with the usual one command (`bash deploy/deploy.sh`); migration `0021` adds
the nullable `scouting_records.photo_key` column. Revert: `bash deploy/deploy.sh --revert`;
the extra column does not bother the older API, but that API refuses sync writes that carry a
`photo_key`, so revert only before any photo was backed up. An older app never sends it.

Optional tuning: `PHOTO_DOWNLOAD_EXPIRY_SECONDS` (default 300), `PHOTO_MAX_BYTES`.

## How it works

- Object path: `<owner_id>/<record_id>.jpg`, derived by the API, never chosen by the phone.
- `POST /v1/scouting/{record_id}/photo-upload-url` (`{"content_type": "image/jpeg",
  "size_bytes": n}`) -> `{upload_url, photo_key, expires_in, max_bytes}`. Supabase signs
  upload URLs for 2 hours. The phone `PUT`s the JPEG there, then saves `photo_key` on the
  record through the normal sync outbox. Sync refuses a `photo_key` that is not exactly the
  caller's `<owner_id>/<record_id>.jpg` (`invalid_photo_key`).
- `GET /v1/scouting/{record_id}/photo-url` -> a download URL valid for 5 minutes.
- Both need the record to be the caller's own, live record (404 otherwise).

## Phone behaviour

- Uploads run after a successful sync, once the record itself is on the server, **on Wi-Fi**
  (recognised from the phone's network interface names; the app has no connectivity plugin),
  or on any connection when the grower turns on Settings -> "Back up photos on mobile data"
  (off by default). Failures retry with backoff (1 min doubling, at most 6 h).
- A backed-up photo shows a small cloud mark in the scouting log. On another phone it is
  downloaded when the log is opened (any connection: the grower asked to see it) and kept.

## Check

- Before the settings: the photo endpoints answer 503 and photos stay on the phone.
- After: add a scouting record with a photo on Wi-Fi; within a sync cycle the cloud mark
  appears and the object is listed under `scouting-photos/<owner_id>/` in the dashboard.
