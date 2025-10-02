import hashlib
import math
import os
import re
from dataclasses import dataclass
from typing import List, Optional

import yaml
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

CONFIG_PATH = os.getenv("RERANKER_CONFIG", "/app/config/config.yaml")

_WORD_RE = re.compile(r"\w+")


@dataclass
class ServiceConfig:
    model_name: str
    trace_header: str
    default_top_k: int


class CandidateDocument(BaseModel):
    text: str
    index: Optional[int] = None
    document_id: Optional[str] = Field(default=None, alias="document_id")
    score: Optional[float] = None
    meta: dict = Field(default_factory=dict)


class RerankRequest(BaseModel):
    trace_id: Optional[str] = Field(default=None, alias="trace_id")
    query: str
    documents: List[CandidateDocument]
    top_k: Optional[int] = Field(default=None, alias="top_k")


class RerankResult(BaseModel):
    index: int
    score: float
    document: CandidateDocument


class RerankResponse(BaseModel):
    model: str
    results: List[RerankResult]


app = FastAPI(title="SHS Local Reranker", version="0.1.0")
_CONFIG: ServiceConfig


def _load_config() -> ServiceConfig:
    with open(CONFIG_PATH, "r", encoding="utf-8") as handle:
        raw = yaml.safe_load(handle)
    scoring = raw.get("scoring", {})
    tracing = raw.get("scoring", {})
    model = raw.get("model", {})
    return ServiceConfig(
        model_name=model.get("name", "shs-hash-reranker"),
        trace_header=scoring.get("trace_header", "X-Trace-Id"),
        default_top_k=int(scoring.get("top_k", 20)),
    )


def _hash_token(token: str) -> int:
    digest = hashlib.sha256(token.encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big")


def _vectorize(text: str, dimension: int = 384) -> List[float]:
    values = [0.0] * dimension
    tokens = _WORD_RE.findall(text.lower())
    if not tokens:
        return values
    for token in tokens:
        hashed = _hash_token(token)
        slot = hashed % dimension
        magnitude = ((hashed >> 9) & 0x3FF) / 1023.0
        if ((hashed >> 19) & 1) == 1:
            magnitude = -magnitude
        values[slot] += magnitude
    norm = math.sqrt(sum(v * v for v in values))
    if norm:
        values = [v / norm for v in values]
    return values


def _dot(lhs: List[float], rhs: List[float]) -> float:
    return sum(a * b for a, b in zip(lhs, rhs))


@app.on_event("startup")
async def startup_event() -> None:
    global _CONFIG
    _CONFIG = _load_config()


@app.middleware("http")
async def attach_trace_header(request: Request, call_next):
    response = await call_next(request)
    trace_header = getattr(_CONFIG, "trace_header", "X-Trace-Id")
    if trace_header not in response.headers and trace_header in request.headers:
        response.headers[trace_header] = request.headers[trace_header]
    return response


@app.get("/healthz")
async def healthz() -> JSONResponse:
    return JSONResponse({"status": "ok"})


@app.get("/readyz")
async def readyz() -> JSONResponse:
    return JSONResponse({"status": "ready", "model": _CONFIG.model_name})


@app.post("/rerank", response_model=RerankResponse)
async def rerank(payload: RerankRequest) -> RerankResponse:
    if not payload.documents:
        raise HTTPException(status_code=400, detail="documents must not be empty")
    query_vec = _vectorize(payload.query)
    scored: List[RerankResult] = []
    for idx, doc in enumerate(payload.documents):
        doc_vec = _vectorize(doc.text)
        score = _dot(query_vec, doc_vec)
        scored.append(RerankResult(index=idx, score=score, document=doc))
    top_k = payload.top_k or _CONFIG.default_top_k
    ranked = sorted(scored, key=lambda item: item.score, reverse=True)[:top_k]
    return RerankResponse(model=_CONFIG.model_name, results=ranked)
