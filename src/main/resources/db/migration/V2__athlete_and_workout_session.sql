-- V2__athlete_and_workout_session.sql

--ATHLETE
create table if not exists athlete (
  id               bigserial primary key,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  external_user_ref varchar(100),
  full_name        varchar(100) not null,
  email            varchar(255),
  constraint uq_athlete_email unique (email)
);

--WORKOUT_SESSION
create table if not exists workout_session (
  id               bigserial primary key,
  athlete_id       bigint not null references athlete(id) on delete cascade,
  session_date     date not null,
  sport            varchar(32) not null,
  duration_minutes int not null check (duration_minutes > 0),
  rpe              smallint not null check (rpe between 1 and 10),
  notes            text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

--index a gyakori lekérdezésekhez
create index if not exists idx_workout_session_athlete_date on workout_session(athlete_id, session_date desc);
create index if not exists idx_workout_session_sport        on workout_session(sport);

--updated_at kezelése
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_athlete_set_updated_at on athlete;
create trigger trg_athlete_set_updated_at
  before update on athlete
  for each row execute function set_updated_at();

drop trigger if exists trg_workout_set_updated_at on workout_session;
create trigger trg_workout_set_updated_at
  before update on workout_session
  for each row execute function set_updated_at();
