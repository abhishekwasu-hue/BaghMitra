FROM python:3.12-slim
WORKDIR /srv
# Optional OCR for scanned / broken-Marathi GR PDFs (docs/runbooks/govt-feed.md §3a). Not
# enabled: uncomment, rebuild and set FEED_OCR_ENABLED=true to use it.
# RUN apt-get update && apt-get install -y --no-install-recommends tesseract-ocr tesseract-ocr-mar poppler-utils && rm -rf /var/lib/apt/lists/*
COPY pyproject.toml ./
COPY src ./src
RUN pip install --no-cache-dir . && useradd --system app
COPY alembic.ini ./
COPY alembic ./alembic
USER app
EXPOSE 8000
CMD ["uvicorn", "bagmitra_api.asgi:app", "--host", "0.0.0.0", "--port", "8000"]
