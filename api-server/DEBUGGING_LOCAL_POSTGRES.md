# Local Debugging Setup

This project uses PostgreSQL locally for development and debugging.

## 1. Create the database

Use your local PostgreSQL server and create a user/database that matches the default app settings:

```sql
CREATE USER seungyo WITH PASSWORD 'seungyo_password';
CREATE DATABASE seungyo OWNER seungyo;
GRANT ALL PRIVILEGES ON DATABASE seungyo TO seungyo;
```

If you already have a different local database, set `DATABASE_URL` in `.env` instead.

## 2. Configure environment variables

Copy `.env.example` to `.env` and adjust values if needed.

The important value is:

```env
DATABASE_URL=postgresql+asyncpg://seungyo:seungyo_password@localhost:5432/seungyo
```

The application uses the async URL at runtime. Alembic converts that URL to a synchronous one automatically for migrations.

## 3. How the DB layer works

- `app/db/session.py` creates an async SQLAlchemy engine with `create_async_engine(...)`.
- `get_db()` yields an `AsyncSession` for FastAPI dependencies.
- `app/db/base.py` imports every model module so `Base.metadata` contains all tables.
- `alembic/env.py` imports `app.db.base` for its side effects, then uses `Base.metadata` for autogenerate.

## 4. How Alembic is wired

- `alembic.ini` contains a placeholder sync URL.
- `alembic/env.py` overwrites that URL from `settings.database_url`.
- `settings.alembic_database_url` strips `+asyncpg` because Alembic uses a synchronous engine.
- `compare_type=True` and `compare_server_default=True` are enabled so autogenerate catches more schema changes.

## 5. Typical commands

After dependencies are installed:

```bash
alembic revision --autogenerate -m "initial"
alembic upgrade head
uvicorn app.main:app --reload
```

After the first revision exists, later schema changes use:

```bash
alembic revision --autogenerate -m "add_new_field"
alembic upgrade head
```

## 6. What to check first when debugging

- Confirm PostgreSQL is running on `localhost:5432`.
- Confirm the `seungyo` user can connect to the `seungyo` database.
- Confirm `.env` is present and `DATABASE_URL` is correct.
- Confirm imports succeed before running Alembic or the app.
