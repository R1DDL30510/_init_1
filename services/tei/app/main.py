import hashlib
import math
import os
import re
from dataclasses import dataclass
from hashlib import sha256
from typing import List, Optional

import asyncpg
import yaml
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

CONFIG_PATH = os.getenv("TEI_CONFIG", "/app/config/config.yaml")

_WORD_RE = re.compile(r"\w+")


@dataclass
class ServiceConfig:
    model_name: str
    embedding_dimension: int
    trace_header: str


class ChunkInput(BaseModel):
    text: str
    index: Optional[int] = None
    meta: dict = Field(default_factory=dict)


class DocumentInfo(BaseModel):
    uri: str
    sha256: str
    mime: str
    size: int


class ChunkOutput(ChunkInput):
    sha256: str


class EmbedRequest(BaseModel):
    trace_id: Optional[str] = Field(default=None, alias="trace_id")
    document: Optional[DocumentInfo] = None
    inputs: List[ChunkInput]


class EmbeddingVector(BaseModel):
    index: int
    vector: str


class EmbedResponse(BaseModel):
    model: str
    document: Optional[DocumentInfo]
    embeddings: List[EmbeddingVector]
    chunks: List[ChunkOutput]


class VectorQueryRequest(BaseModel):
    trace_id: Optional[str] = Field(default=None, alias="trace_id")
    query: str
    top_k: Optional[int] = Field(default=None, alias="top_k")


class Citation(BaseModel):
    document_id: str
    uri: str
    chunk_index: int
    text: str
    score: float
    meta: dict


class VectorQueryResponse(BaseModel):
    model: str
    query: str
    top_k: int
    citations: List[Citation]


app = FastAPI(title="SHS Local TEI", version="0.1.0")
_CONFIG: ServiceConfig
_POOL: Optional[asyncpg.Pool] = None


def _load_config() -> ServiceConfig:
    with open(CONFIG_PATH, "r", encoding="utf-8") as handle:
        raw = yaml.safe_load(handle)
    model = raw.get("model", {})
    tracing = raw.get("tracing", {})
    return ServiceConfig(
        model_name=model.get("name", "shs-hash-tei"),
        embedding_dimension=int(model.get("embedding_dimension", 384)),
        trace_header=tracing.get("header", "X-Trace-Id"),
    )


def _hash_token(token: str) -> int:
    digest = hashlib.sha256(token.encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big")


def _embed(text: str, dimension: int) -> List[float]:
    values = [0.0] * dimension
    tokens = _WORD_RE.findall(text.lower())
    if not tokens:
        return values
    for token in tokens:
        hashed = _hash_token(token)
        slot = hashed % dimension
        magnitude = ((hashed >> 11) & 0xFFF) / 4095.0
        if ((hashed >> 23) & 0x1) == 1:
            magnitude = -magnitude
        values[slot] += magnitude
    norm = math.sqrt(sum(v * v for v in values))
    if norm:
        values = [v / norm for v in values]
    return values


def _to_vector_literal(values: List[float]) -> str:
    return "[" + ",".join(f"{v:.6f}" for v in values) + "]"


async def _vector_search(vector_literal: str, top_k: int) -> List[Citation]:
    if _POOL is None:
        raise RuntimeError("database pool not initialised")
    async with _POOL.acquire() as connection:
        rows = await connection.fetch(
            """
            WITH query_vec AS (SELECT $1::vector AS vec)
            SELECT d.id AS document_id,
                   d.uri AS uri,
                   c.chunk_ix AS chunk_index,
                   c.text AS text,
                   c.meta_json AS meta,
                   1 - (e.vec <=> (SELECT vec FROM query_vec)) AS score
            FROM embeddings e
            JOIN chunks c ON c.id = e.chunk_id
            JOIN documents d ON d.id = c.document_id
            WHERE d.deleted_at IS NULL
            ORDER BY e.vec <=> (SELECT vec FROM query_vec)
            LIMIT $2
            """,
            vector_literal,
            top_k,
        )
    citations: List[Citation] = []
    for row in rows:
        meta = row["meta"]
        if isinstance(meta, str):
            try:
                meta = yaml.safe_load(meta)
            except Exception:
                meta = {"raw": meta}
        citations.append(
            Citation(
                document_id=str(row["document_id"]),
                uri=row["uri"],
                chunk_index=row["chunk_index"],
                text=row["text"],
                score=float(row["score"]),
                meta=meta if isinstance(meta, dict) else {},
            )
        )
    return citations


def _database_dsn() -> str:
    host = os.getenv("POSTGRES_HOST", "postgres")
    port = int(os.getenv("POSTGRES_PORT", "5432"))
    db = os.getenv("POSTGRES_DB", "shs")
    user = os.getenv("POSTGRES_USER", "shs_app")
    password = os.getenv("POSTGRES_PASSWORD")
    if not password:
        raise RuntimeError("POSTGRES_PASSWORD is required")
    return f"postgresql://{user}:{password}@{host}:{port}/{db}"


@app.on_event("startup")
async def startup_event() -> None:
    global _CONFIG, _POOL
    _CONFIG = _load_config()
    _POOL = await asyncpg.create_pool(dsn=_database_dsn(), min_size=1, max_size=4)


@app.middleware("http")
async def attach_trace_header(request: Request, call_next):
    response = await call_next(request)
    trace_header = getattr(_CONFIG, "trace_header", "X-Trace-Id")
    if trace_header not in response.headers and trace_header in request.headers:
        response.headers[trace_header] = request.headers[trace_header]
    return response


@app.on_event("shutdown")
async def shutdown_event() -> None:
    global _POOL
    if _POOL:
        await _POOL.close()


@app.get("/healthz")
async def healthz() -> JSONResponse:
    return JSONResponse({"status": "ok"})


@app.get("/readyz")
async def readyz() -> JSONResponse:
    return JSONResponse({"status": "ready", "model": _CONFIG.model_name})


@app.post("/embed", response_model=EmbedResponse)
async def embed_vectors(payload: EmbedRequest, request: Request) -> EmbedResponse:
    if not payload.inputs:
        raise HTTPException(status_code=400, detail="inputs must not be empty")
    enriched_chunks: List[ChunkOutput] = []
    embeddings: List[EmbeddingVector] = []
    for idx, chunk in enumerate(payload.inputs):
        digest = sha256(chunk.text.encode("utf-8")).hexdigest()
        enriched_chunks.append(
            ChunkOutput(text=chunk.text, index=chunk.index, meta=chunk.meta, sha256=digest)
        )
        vector = _embed(chunk.text, _CONFIG.embedding_dimension)
        embeddings.append(EmbeddingVector(index=idx, vector=_to_vector_literal(vector)))
    return EmbedResponse(
        model=_CONFIG.model_name,
        document=payload.document,
        embeddings=embeddings,
        chunks=enriched_chunks,
    )


@app.post("/api/vector_query", response_model=VectorQueryResponse)
async def vector_query(payload: VectorQueryRequest) -> VectorQueryResponse:
    if not payload.query:
        raise HTTPException(status_code=400, detail="query must not be empty")
    top_k = payload.top_k or 5
    query_vec = _embed(payload.query, _CONFIG.embedding_dimension)
    citations = await _vector_search(_to_vector_literal(query_vec), top_k)
    return VectorQueryResponse(
        model=_CONFIG.model_name,
        query=payload.query,
        top_k=top_k,
        citations=citations,
    )
