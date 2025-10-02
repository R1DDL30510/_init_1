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

CREATE OR REPLACE FUNCTION shs_ingest_upsert(
    doc_json jsonb,
    chunks_json jsonb,
    embeddings_json jsonb,
    model_name text
) RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    doc_id uuid;
BEGIN
    IF doc_json IS NULL THEN
        RAISE EXCEPTION 'document payload missing';
    END IF;

    SELECT id INTO doc_id FROM documents WHERE sha256 = doc_json->>'sha256';

    IF doc_id IS NULL THEN
        INSERT INTO documents (uri, mime, sha256, size)
        VALUES (
            doc_json->>'uri',
            COALESCE(doc_json->>'mime', 'application/octet-stream'),
            doc_json->>'sha256',
            COALESCE((doc_json->>'size')::bigint, 0)
        )
        RETURNING id INTO doc_id;
    ELSE
        UPDATE documents
        SET
            uri = COALESCE(doc_json->>'uri', uri),
            mime = COALESCE(doc_json->>'mime', mime),
            size = COALESCE((doc_json->>'size')::bigint, size),
            updated_at = now()
        WHERE id = doc_id;
        DELETE FROM chunks WHERE document_id = doc_id;
    END IF;

    WITH chunk_payload AS (
        SELECT
            COALESCE((value->>'index')::int, (ord - 1)) AS chunk_ix,
            value->>'text' AS text,
            COALESCE(value->'meta', '{}'::jsonb) AS meta,
            value->>'sha256' AS sha
        FROM jsonb_array_elements(chunks_json) WITH ORDINALITY AS elem(value, ord)
    ),
    inserted_chunks AS (
        INSERT INTO chunks (document_id, chunk_ix, text, meta_json, sha256)
        SELECT doc_id, chunk_ix, text, meta, sha
        FROM chunk_payload
        RETURNING id, chunk_ix
    ),
    embedding_payload AS (
        SELECT
            COALESCE((value->>'index')::int, (ord - 1)) AS chunk_ix,
            value->>'vector' AS vector_literal
        FROM jsonb_array_elements(embeddings_json) WITH ORDINALITY AS elem(value, ord)
    )
    INSERT INTO embeddings (chunk_id, vec, model)
    SELECT ic.id, (ep.vector_literal)::vector, COALESCE(model_name, 'shs-hash-embedding')
    FROM inserted_chunks ic
    JOIN embedding_payload ep USING (chunk_ix);

    RETURN doc_id;
END;
$$;
