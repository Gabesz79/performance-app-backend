-- V1__init.sql
-- Kezdő (baseline) séma: egyszerű users tábla
-- Az id-t az alkalmazás (UUID) fogja adni, nem az adatbázis auto-increment.

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
