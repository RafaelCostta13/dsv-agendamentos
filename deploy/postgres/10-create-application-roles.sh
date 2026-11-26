#!/bin/sh
set -eu

if [ "$POSTGRES_USER" = "$POSTGRES_APP_USER" ]; then
  echo "PostgreSQL admin and application role names must be distinct." >&2
  exit 1
fi

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --set ON_ERROR_STOP=1 <<'SQL'
\getenv app_role POSTGRES_APP_USER
\getenv app_password POSTGRES_APP_PASSWORD

SELECT format(
  'CREATE ROLE %I LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS',
  :'app_role', :'app_password'
) \gexec

SELECT format('REVOKE CONNECT ON DATABASE %I FROM PUBLIC', current_database()) \gexec
SELECT format('GRANT CONNECT ON DATABASE %I TO %I', current_database(), :'app_role') \gexec
GRANT USAGE, CREATE ON SCHEMA public TO :"app_role";
SQL
