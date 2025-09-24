-- V1__init.sql
-- Kezdő (baseline) séma: egyszerű users tábla
-- Az id-t az alkalmazás (UUID) fogja adni, nem az adatbázis auto-increment.

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email VARCHAR(320) NOT NULL UNIQUE,
  display_name VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
