CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

CREATE ROLE shs_app_r NOLOGIN;
CREATE ROLE shs_app_rw NOLOGIN;

CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    uri TEXT NOT NULL,
    mime TEXT NOT NULL,
    sha256 CHAR(64) NOT NULL UNIQUE,
    size BIGINT NOT NULL CHECK (size >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ NULL
);

CREATE TABLE IF NOT EXISTS chunks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    chunk_ix INTEGER NOT NULL CHECK (chunk_ix >= 0),
    text TEXT NOT NULL,
    meta_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    sha256 CHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (document_id, chunk_ix)
);

CREATE TABLE IF NOT EXISTS embeddings (
    chunk_id UUID PRIMARY KEY REFERENCES chunks(id) ON DELETE CASCADE,
    vec vector(384) NOT NULL,
    model TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_documents_sha256 ON documents USING hash (sha256);
CREATE INDEX IF NOT EXISTS idx_chunks_sha256 ON chunks USING hash (sha256);
CREATE INDEX IF NOT EXISTS idx_embeddings_vec ON embeddings USING ivfflat (vec vector_cosine_ops) WITH (lists = 100);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE embeddings ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA public TO shs_app_r, shs_app_rw;
GRANT SELECT ON documents, chunks, embeddings TO shs_app_r;
GRANT SELECT, INSERT, UPDATE, DELETE ON documents, chunks, embeddings TO shs_app_rw;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO shs_app_rw;
