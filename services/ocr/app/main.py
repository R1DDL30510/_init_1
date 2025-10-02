import io
import json
import mimetypes
import os
import re
from dataclasses import dataclass
from hashlib import sha256
from typing import List, Optional, Tuple

import yaml
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from minio import Minio
from pydantic import BaseModel, Field
from pypdf import PdfReader

CONFIG_PATH = os.getenv("OCR_CONFIG", "/app/config/config.yaml")

_S3_RE = re.compile(r"^s3://(?P<bucket>[^/]+)/(?P<key>.+)$")
_FAIL_NEXT = False
_CLIENT: Optional[Minio] = None
_CONFIG: "OCRConfig"


@dataclass
class StorageConfig:
    endpoint: str
    bucket: str
    secure: bool
    access_key_env: str
    secret_key_env: str


@dataclass
class OCRConfig:
    trace_header: str
    storage: StorageConfig


class OCRRequest(BaseModel):
    uri: str
    trace_id: Optional[str] = Field(default=None, alias="trace_id")


class OCRResponsePage(BaseModel):
    index: int
    text: str
    sha256: str


class OCRResponse(BaseModel):
    document: dict
    pages: List[OCRResponsePage]


app = FastAPI(title="SHS Local OCR", version="0.1.0")


def _load_config() -> OCRConfig:
    with open(CONFIG_PATH, "r", encoding="utf-8") as handle:
        raw = yaml.safe_load(handle)
    service = raw.get("service", {})
    storage = raw.get("storage", {})
    return OCRConfig(
        trace_header=service.get("trace_header", "X-Trace-Id"),
        storage=StorageConfig(
            endpoint=storage.get("endpoint", "minio:9000"),
            bucket=storage.get("bucket", "shs"),
            secure=bool(storage.get("secure", False)),
            access_key_env=storage.get("access_key_env", "MINIO_ROOT_USER"),
            secret_key_env=storage.get("secret_key_env", "MINIO_ROOT_PASSWORD"),
        ),
    )


def _client() -> Minio:
    global _CLIENT
    if _CLIENT is None:
        access_key = os.getenv(_CONFIG.storage.access_key_env)
        secret_key = os.getenv(_CONFIG.storage.secret_key_env)
        if not access_key or not secret_key:
            raise RuntimeError("Missing MinIO credentials")
        _CLIENT = Minio(
            endpoint=_CONFIG.storage.endpoint,
            access_key=access_key,
            secret_key=secret_key,
            secure=_CONFIG.storage.secure,
        )
    return _CLIENT


def _parse_uri(uri: str) -> Tuple[str, str]:
    match = _S3_RE.match(uri)
    if not match:
        raise ValueError("Unsupported URI")
    return match.group("bucket"), match.group("key")


def _extract_text(key: str, data: bytes) -> List[OCRResponsePage]:
    mime, _ = mimetypes.guess_type(key)
    if mime == "application/pdf":
        reader = PdfReader(io.BytesIO(data))
        pages: List[OCRResponsePage] = []
        for idx, page in enumerate(reader.pages):
            text = page.extract_text() or ""
            digest = sha256(text.encode("utf-8")).hexdigest()
            pages.append(OCRResponsePage(index=idx, text=text, sha256=digest))
        if not pages:
            digest = sha256(data).hexdigest()
            pages.append(OCRResponsePage(index=0, text="", sha256=digest))
        return pages
    if mime in {"text/plain", "text/csv"}:
        try:
            decoded = data.decode("utf-8")
        except UnicodeDecodeError:
            decoded = data.decode("latin-1", errors="ignore")
        digest = sha256(decoded.encode("utf-8")).hexdigest()
        return [OCRResponsePage(index=0, text=decoded, sha256=digest)]
    if mime and mime.startswith("image/"):
        digest = sha256(data).hexdigest()
        placeholder = f"Image content {digest[:16]}"
        page_hash = sha256(placeholder.encode("utf-8")).hexdigest()
        return [OCRResponsePage(index=0, text=placeholder, sha256=page_hash)]
    digest = sha256(data).hexdigest()
    fallback = data.decode("utf-8", errors="ignore")
    page_hash = sha256(fallback.encode("utf-8")).hexdigest()
    return [OCRResponsePage(index=0, text=fallback, sha256=page_hash)]


@app.on_event("startup")
async def startup_event() -> None:
    global _CONFIG
    _CONFIG = _load_config()


@app.middleware("http")
async def attach_trace_header(request: Request, call_next):
    response = await call_next(request)
    header = getattr(_CONFIG, "trace_header", "X-Trace-Id")
    if header not in response.headers and header in request.headers:
        response.headers[header] = request.headers[header]
    return response


@app.get("/healthz")
async def healthz() -> JSONResponse:
    return JSONResponse({"status": "ok"})


@app.get("/readyz")
async def readyz() -> JSONResponse:
    return JSONResponse({"status": "ready"})


@app.post("/admin/simulate-failure")
async def simulate_failure(request: Request) -> JSONResponse:
    global _FAIL_NEXT
    _FAIL_NEXT = True
    payload = await request.json()
    trace_id = payload.get("trace_id") if isinstance(payload, dict) else None
    return JSONResponse({"status": "armed", "trace_id": trace_id})


@app.post("/ocr", response_model=OCRResponse)
async def perform_ocr(payload: OCRRequest, request: Request) -> OCRResponse:
    global _FAIL_NEXT
    if _FAIL_NEXT:
        _FAIL_NEXT = False
        raise HTTPException(status_code=503, detail="simulated failure")
    try:
        bucket, key = _parse_uri(payload.uri)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if bucket != _CONFIG.storage.bucket:
        raise HTTPException(status_code=404, detail="bucket not permitted")
    client = _client()
    try:
        response = client.get_object(bucket, key)
        data = response.read()
    except Exception as exc:  # pragma: no cover - network errors pass through
        raise HTTPException(status_code=502, detail="object retrieval failed") from exc
    finally:
        try:
            response.close()
            response.release_conn()
        except Exception:
            pass
    sha_value = sha256(data).hexdigest()
    pages = _extract_text(key, data)
    document = {
        "uri": payload.uri,
        "sha256": sha_value,
        "mime": mimetypes.guess_type(key)[0] or "application/octet-stream",
        "size": len(data),
    }
    return OCRResponse(document=document, pages=pages)
