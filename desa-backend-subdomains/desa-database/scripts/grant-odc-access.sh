#!/usr/bin/env bash
# =============================================================================
# DESA – grant read access on the ODC schema
# -----------------------------------------------------------------------------
# Run AFTER the ODC tables exist, i.e. after either
#   * `datacube system init` (fresh index), or
#   * scripts/migrate-from-remote.sh (restored index).
# Safe to re-run.
#
#   ./scripts/grant-odc-access.sh
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

DB_CONTAINER=${DB_CONTAINER:-desa-db}
ODC_DB=${ODC_DB:-datacube}
ODC_ADMIN_USER=${ODC_ADMIN_USER:-odc_admin}
ODC_READER_USER=${ODC_READER_USER:-odc_reader}
EXPLORER_USER=${EXPLORER_USER:-odc_explorer}

docker exec -i "$DB_CONTAINER" psql -v ON_ERROR_STOP=1 -U "${POSTGRES_SUPERUSER:-postgres}" -d "$ODC_DB" \
  -v odc_admin="$ODC_ADMIN_USER" -v odc_reader="$ODC_READER_USER" -v explorer="$EXPLORER_USER" <<'SQL'
-- Store role names where the DO block can read them
SELECT set_config('desa.odc_admin',  :'odc_admin',  false),
       set_config('desa.odc_reader', :'odc_reader', false),
       set_config('desa.explorer',   :'explorer',   false);

DO $$
DECLARE
  admin_r  text := current_setting('desa.odc_admin');
  reader_r text := current_setting('desa.odc_reader');
  expl_r   text := current_setting('desa.explorer');
  s        text;
  found    int  := 0;
BEGIN
  -- ODC 1.8 uses schema "agdc"; ODC 1.9 postgis driver uses "odc".
  FOREACH s IN ARRAY ARRAY['agdc', 'odc'] LOOP
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = s) THEN
      found := found + 1;
      EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I, %I', s, reader_r, expl_r);
      EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO %I, %I', s, reader_r, expl_r);
      EXECUTE format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA %I TO %I, %I', s, reader_r, expl_r);
      EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %I TO %I, %I', s, reader_r, expl_r);
      -- Tables created later by odc_admin (new products) inherit the grants
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO %I, %I',
                     admin_r, s, reader_r, expl_r);
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON SEQUENCES TO %I, %I',
                     admin_r, s, reader_r, expl_r);
      RAISE NOTICE 'Granted read on schema % to %, %', s, reader_r, expl_r;
    END IF;
  END LOOP;

  IF found = 0 THEN
    RAISE EXCEPTION 'No ODC schema (agdc/odc) in this database yet - run "datacube system init" or the migration first';
  END IF;

  -- ODC's own group role, created by `datacube system init` / restored dumps
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'agdc_user') THEN
    EXECUTE format('GRANT agdc_user TO %I, %I', reader_r, expl_r);
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'agdc_admin') THEN
    EXECUTE format('GRANT agdc_admin TO %I', admin_r);
  END IF;
END $$;
SQL

echo ">>> Read access granted. Reader: ${ODC_READER_USER}  Explorer: ${EXPLORER_USER}"
