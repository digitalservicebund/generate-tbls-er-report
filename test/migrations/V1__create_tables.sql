CREATE TABLE author (
    id      BIGSERIAL PRIMARY KEY,
    name    TEXT        NOT NULL,
    email   TEXT        NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE document (
    id          BIGSERIAL PRIMARY KEY,
    title       TEXT        NOT NULL,
    body        TEXT,
    author_id   BIGINT      NOT NULL,
    published   BOOLEAN     NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
