# ER-diagram (domain, v0.3.4)

Az ábra a JPA entitások és a Flyway migrációk alapján készült.
- Entitások: `Athlete`, `WorkoutSession` (`Sport` enum STRING-ként tárolva)
- Fő forrás: `V2__athlete_and_workout_session.sql`, későbbi módosítások: `V3`–`V5` (Athlete név mezők), seed: `V6`.

```mermaid
erDiagram
  %% Kapcsolat: 1 Athlete -> N WorkoutSession
  ATHLETE ||--o{ WORKOUT_SESSION : has

  ATHLETE {
    BIGINT      id PK "IDENTITY / bigserial"
    VARCHAR     external_user_ref "max 100"
    VARCHAR     full_name NN "max 100"
    VARCHAR     email "max 255, UNIQUE"
    TIMESTAMPTZ created_at NN
    TIMESTAMPTZ updated_at NN
  }

  WORKOUT_SESSION {
    BIGINT      id PK "IDENTITY / bigserial"
    DATE        session_date NN
    VARCHAR     sport NN "enum: RUN|BIKE|SWIM|GYM|YOGA|OTHER (STRING)"
    INTEGER     duration_minutes NN
    SMALLINT    rpe NN
    TEXT        notes
    TIMESTAMPTZ created_at NN
    TIMESTAMPTZ updated_at NN
    BIGINT      athlete_id NN FK "→ ATHLETE.id"
  }

Megjegyzések és konvenciók

PK/ID: mindkét táblában auto-generált (IDENTITY / bigserial).
Időbélyegek: created_at, updated_at NOT NULL, updated_at frissítése triggerrel történik.

ATHLETE
full_name kötelező (V2 hozta létre 100 karakterrel; V4–V5 migration-ok a régi name mezőt konszolidálták full_name-ra).
email opcionális, egyedi (uq_athlete_email).
external_user_ref opcionális (külső azonosítóhoz fenntartva).

WORKOUT_SESSION
session_date, sport, duration_minutes, rpe kötelezők.
sport a Sport enum STRING reprezentációja: RUN | BIKE | SWIM | GYM | YOGA | OTHER.
athlete_id kötelező FK → athlete(id).
notes opcionális szövegmező.
