# Contributing

Köszönjük, hogy hozzájárulsz a **performance-app-backend** projekthez! Az alábbi útmutató segít gyorsan, egységesen és biztonságosan dolgozni.

## Előfeltételek
- Java 17/21
- Docker Desktop (Compose)
- Git
- IntelliJ IDEA (ajánlott)
- Windows/PowerShell (példák ehhez igazodnak)

## Gyors indítás

### Lokális fejlesztés (local profil)
1. Docker Desktop indítása
2. Shell profil beállítás (ha új PowerShell ablak):
   $env:SPRING_PROFILES_ACTIVE="local"
3. Infrastruktúra:
   docker compose up -d
4. Alkalmazás:
   .\gradlew bootRun
5. Health check:
   iwr http://localhost:8080/api/healthz | % Content   # elvárt: ok
6. Swagger UI: http://localhost:8080/swagger-ui/index.html

### Portfólió bemutató futtatás (portfolio profil, 8084)
- Indítás (háttér, logolás):
  .\portfolio-start.bat
  Health: http://localhost:8084/api/healthz  → ok
  Swagger: http://localhost:8084/swagger-ui/index.html
  Log: .run\portfolio-bootrun-YYYYMMDD-HHMMSS.log
- Leállítás:
  .\portfolio-stop.bat

> Tipp: a .run/ mappát ne commitold (a repo .gitignore már tartalmazza).

## Branching és PR folyamat
- A main védett → közvetlen push tilos. Minden változtatás külön branch + Pull Request (PR).
- Új ág a main-ről:
  git fetch origin
  git switch -c feat/valtoztatasod origin/main
- Dolgozz, commitolj (lásd lent: Conventional Commits), majd:
  git push -u origin feat/valtoztatasod
- Nyiss PR-t GitHubon (PR sablon automatikus).
- CODEOWNERS alapján alap reviewer: @Gabesz79.

## Commit szabályok – Conventional Commits
Használd az alábbi előtagokat:
- feat: új funkció
- fix: hiba javítása
- docs: dokumentáció
- chore: karbantartás/infra
- refactor: viselkedés nem változik
- test: tesztelés
- perf: teljesítmény
- ci: CI/CD, build, pipeline
- style: formázás, linter (kódlogika nélkül)
- revert: visszavonás

Példa: feat(api): add workouts summary endpoint
Opcionális scope: feat(auth): …, fix(db): …

## PR-ellenőrzőlista (Definition of Done)
- [ ] Build és tesztek zöldek:
      .\gradlew clean test
- [ ] Health rendben (futó profil szerint):
      iwr http://localhost:8080/api/healthz | % Content   # vagy 8084 portfolio esetén
- [ ] Swagger UI elérhető (és naprakész, ha API változott)
- [ ] Nincsenek titkok (jelszó, token, .env) a diffben
- [ ] Flyway migrációk (ha kellett) rendben futnak
- [ ] Breaking change jelölve és migráció leírva (ha van)
- [ ] README/Docs frissítve, ha releváns
- [ ] PR leírás kitöltve (miért, hogyan, tesztek, képek/logkivonatok, kapcsolódó issue-k)

## Tesztelés – gyors parancsok
- Unit/Integrációs tesztek:
      .\gradlew clean test
- Alap funkcionális próba:
      iwr http://localhost:8080/api/healthz | % Content
- Actuator (ha BasicAuth kell):
      $cred = [pscredential]::new('perf_user',(ConvertTo-SecureString 'Perf_1234!' -AsPlainText -Force))
      Invoke-RestMethod -Uri 'http://localhost:8084/actuator/health' -Authentication Basic -Credential $cred -AllowUnencryptedAuthentication

## Kódstílus és minőség
- Tartsd a rétegezést: controller → service → repository.
- Validáció: Bean Validation (Spring Validation annotációk).
- Kerüld a breaking change-eket; ha elkerülhetetlen, jelezd a PR-ban.
- Logolás: lényegre törő, PII/secret ne kerüljön logba.

## Biztonság
- Ne commitolj credentialeket vagy privát kulcsokat.
- Sérülékenység bejelentése: lásd SECURITY.md.
- Harmadik féltől származó frissítések: Dependabot PR-ek jöhetnek.

## Kiadások és verziózás
- Release jegyzeteket a Release Drafter készíti (PR címekből/label-ekből).
- Verziózás: Semantic Versioning (MAJOR.MINOR.PATCH).

## Közreműködés
Kérdésed van? Nyiss issue-t (Bug/Feature sablon), vagy jelezd a PR-odban, mire kérsz fókuszt a review során.
Köszönjük a hozzájárulást! 🙌
