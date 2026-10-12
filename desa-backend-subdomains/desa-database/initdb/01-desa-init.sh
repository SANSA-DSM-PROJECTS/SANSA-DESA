#!/usr/bin/env bash
# =============================================================================
# DESA – first-start database initialisation
# -----------------------------------------------------------------------------
# Runs automatically ONCE, when the desa_db_data volume is empty.
# Creates roles and databases; it does NOT create the ODC schema – that is done
# by `datacube system init` (fresh start) or by restoring a dump (migration).
#
# Roles:
#   odc_admin     owns datacube; used for system init, product add, dataset add
#   odc_reader    read-only on datacube; OWS, JupyterHub users
#   odc_explorer  reads ODC tables, owns the cubedash schema (Explorer)
#   geoserver_app owns geoserver_vector; no access to datacube
# =============================================================================
set -euo pipefail

: "${ODC_DB:?}" "${ODC_ADMIN_USER:?}" "${ODC_ADMIN_PASSWORD:?}"
: "${ODC_READER_USER:?}" "${ODC_READER_PASSWORD:?}"
: "${EXPLORER_USER:?}" "${EXPLORER_PASSWORD:?}"
: "${GS_VECTOR_DB:?}" "${GS_VECTOR_USER:?}" "${GS_VECTOR_PASSWORD:?}"

psql_su() {
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" "$@"
}

echo ">>> DESA init: roles"
psql_su --dbname postgres \
  -v odc_admin="$ODC_ADMIN_USER"     -v odc_admin_pw="$ODC_ADMIN_PASSWORD" \
  -v odc_reader="$ODC_READER_USER"   -v odc_reader_pw="$ODC_READER_PASSWORD" \
  -v explorer="$EXPLORER_USER"       -v explorer_pw="$EXPLORER_PASSWORD" \
  -v gs_user="$GS_VECTOR_USER"       -v gs_pw="$GS_VECTOR_PASSWORD" <<'SQL'
CREATE ROLE :"odc_admin"  LOGIN CREATEROLE PASSWORD :'odc_admin_pw';
CREATE ROLE :"odc_reader" LOGIN            PASSWORD :'odc_reader_pw';
CREATE ROLE :"explorer"   LOGIN            PASSWORD :'explorer_pw';
CREATE ROLE :"gs_user"    LOGIN            PASSWORD :'gs_pw';

-- Sensible guard-rails on the read-only / app roles
ALTER ROLE :"odc_reader" SET statement_timeout = '5min';
ALTER ROLE :"gs_user"    SET statement_timeout = '2min';
ALTER ROLE :"odc_reader" SET idle_in_transaction_session_timeout = '10min';
SQL

echo ">>> DESA init: databases"
psql_su --dbname postgres \
  -v odc_db="$ODC_DB" -v odc_admin="$ODC_ADMIN_USER" \
  -v gs_db="$GS_VECTOR_DB" -v gs_user="$GS_VECTOR_USER" <<'SQL'
CREATE DATABASE :"odc_db" OWNER :"odc_admin" ENCODING 'UTF8' TEMPLATE template0;
CREATE DATABASE :"gs_db"  OWNER :"gs_user"   ENCODING 'UTF8' TEMPLATE template0;

-- Nobody connects by default; access is granted explicitly below.
REVOKE CONNECT, TEMPORARY ON DATABASE :"odc_db" FROM PUBLIC;
REVOKE CONNECT, TEMPORARY ON DATABASE :"gs_db"  FROM PUBLIC;
SQL

echo ">>> DESA init: datacube (${ODC_DB})"
psql_su --dbname "$ODC_DB" \
  -v odc_db="$ODC_DB" -v odc_admin="$ODC_ADMIN_USER" \
  -v odc_reader="$ODC_READER_USER" -v explorer="$EXPLORER_USER" <<'SQL'
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS btree_gist;   -- Explorer spatial/time indexes
CREATE EXTENSION IF NOT EXISTS pg_trgm;

GRANT CONNECT, TEMPORARY ON DATABASE :"odc_db" TO :"odc_admin";
GRANT CONNECT            ON DATABASE :"odc_db" TO :"odc_reader", :"explorer";

-- Explorer creates and owns its own schema
GRANT CREATE ON DATABASE :"odc_db" TO :"explorer";

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT  USAGE  ON SCHEMA public TO :"odc_reader", :"explorer";
SQL

echo ">>> DESA init: geoserver vector (${GS_VECTOR_DB})"
psql_su --dbname "$GS_VECTOR_DB" \
  -v gs_db="$GS_VECTOR_DB" -v gs_user="$GS_VECTOR_USER" <<'SQL'
CREATE EXTENSION IF NOT EXISTS postgis;

GRANT CONNECT, TEMPORARY ON DATABASE :"gs_db" TO :"gs_user";

CREATE SCHEMA IF NOT EXISTS water      AUTHORIZATION :"gs_user";
CREATE SCHEMA IF NOT EXISTS boundaries AUTHORIZATION :"gs_user";

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT  USAGE  ON SCHEMA public TO :"gs_user";
SQL

echo ">>> DESA init: done. Next: 'datacube system init' or scripts/migrate-from-remote.sh"
