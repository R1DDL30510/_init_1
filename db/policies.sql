ALTER TABLE documents FORCE ROW LEVEL SECURITY;
ALTER TABLE chunks FORCE ROW LEVEL SECURITY;
ALTER TABLE embeddings FORCE ROW LEVEL SECURITY;

CREATE POLICY documents_read ON documents FOR SELECT
    TO shs_app_r, shs_app_rw
    USING (deleted_at IS NULL);

CREATE POLICY documents_write ON documents FOR ALL
    TO shs_app_rw
    USING (true)
    WITH CHECK (deleted_at IS NULL OR deleted_at > now());

CREATE POLICY chunks_read ON chunks FOR SELECT
    TO shs_app_r, shs_app_rw
    USING (
        EXISTS (
            SELECT 1 FROM documents d
            WHERE d.id = chunks.document_id
              AND d.deleted_at IS NULL
        )
    );

CREATE POLICY chunks_write ON chunks FOR ALL
    TO shs_app_rw
    USING (true)
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM documents d
            WHERE d.id = chunks.document_id
        )
    );

CREATE POLICY embeddings_read ON embeddings FOR SELECT
    TO shs_app_r, shs_app_rw
    USING (
        EXISTS (
            SELECT 1 FROM chunks c
            JOIN documents d ON d.id = c.document_id
            WHERE c.id = embeddings.chunk_id
              AND d.deleted_at IS NULL
        )
    );

CREATE POLICY embeddings_write ON embeddings FOR ALL
    TO shs_app_rw
    USING (true)
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM chunks c
            WHERE c.id = embeddings.chunk_id
        )
    );
