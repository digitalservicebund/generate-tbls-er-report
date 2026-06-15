CREATE TABLE tag (
    id   BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE document_tag (
    document_id BIGINT NOT NULL REFERENCES document (id) ON DELETE CASCADE,
    tag_id      BIGINT NOT NULL REFERENCES tag (id) ON DELETE CASCADE,
    PRIMARY KEY (document_id, tag_id)
);
