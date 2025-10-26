# Performance App Backend

[![build](https://github.com/Gabesz79/performance-app-backend/actions/workflows/build.yml/badge.svg)](https://github.com/Gabesz79/performance-app-backend/actions/workflows/build.yml)
[![CodeQL](https://github.com/Gabesz79/performance-app-backend/actions/workflows/codeql.yml/badge.svg)](https://github.com/Gabesz79/performance-app-backend/actions/workflows/codeql.yml)
[![Latest release](https://img.shields.io/github/v/release/Gabesz79/performance-app-backend?sort=semver)](https://github.com/Gabesz79/performance-app-backend/releases)

Egyszerű Spring Boot alapú backend fitnesz edzések (WorkoutSession) kezeléséhez: CRUD, keresés/összegzés, egészségügyi végpontok és Swagger UI.

## Quickstart (helyi)

- **Portfolio profil (8084)** – komplett demo adatbázissal:
  1) `.\portfolio-start.bat`  
  2) Swagger: <http://localhost:8084/swagger-ui/index.html>  
  3) Health: <http://localhost:8084/api/healthz> → `ok`  
  4) Actuator (BasicAuth): `perf_user / Perf_1234!` → <http://localhost:8084/actuator/health>  
  5) Leállítás: `.\portfolio-stop.bat`

- **Egyéb profilok**  
  - DEV (8080), PROD (8082) – az `application-*.yml` szerint (Swagger PROD-on ideiglenesen engedélyezve).

## Példa API-k

- Összegzés (időszakra):  
  `GET /api/workouts/summary?from=2025-09-28&to=2025-10-05` → `{"totalSessions":8,"totalMinutes":340,"avgRpe":5.875}`

- Health:  
  `GET /api/healthz` → `ok`

## Architektúra röviden

- **DB migráció:** Flyway (V1…V6, seed adatokkal)
- **Biztonság:** Actuator BasicAuth DEV-en (felhasználó: `perf_user`)
- **CI:** GitHub Actions Build + CodeQL (badge-ek fent)
- **Release kezelés:** Release Drafter (draft → publish), tagek: `v0.0.1 … v0.3.4`

## ER-diagram

Részletesen: [docs/er-diagram.md](docs/er-diagram.md)

---
