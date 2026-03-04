#!/bin/bash
# Initialises the turm database on the first Postgres container start.
# Runs automatically from /docker-entrypoint-initdb.d/ as the POSTGRES_USER superuser.
set -e

# Create the application user and database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
    --command "CREATE USER turm WITH PASSWORD '${TURM_DB_PASSWORD:?TURM_DB_PASSWORD is not set}';"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
    --command "CREATE DATABASE turm OWNER turm;"

# Enable pgcrypto (requires superuser)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname turm \
    --command "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

# Apply the initial schema and all incremental changes as the app user
psql -v ON_ERROR_STOP=1 --username turm --dbname turm -f /scripts/db/create.sql
psql -v ON_ERROR_STOP=1 --username turm --dbname turm -f /scripts/db/changeLog.sql

# Insert test users (admin, lehrer, student)
psql -v ON_ERROR_STOP=1 --username turm --dbname turm -f /docker/init-test-data.sql
