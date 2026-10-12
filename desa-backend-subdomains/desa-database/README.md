# desa-db — DESA database stack
```
                         desa-net (external Docker network)
   ┌──────────┐ ┌──────────┐ ┌────────────┐ ┌───────────┐ ┌───────────┐
   │   OWS    │ │ Explorer │ │ JupyterHub │ │ indexing  │ │ GeoServer │
   │odc_reader│ │odc_explor│ │ odc_reader │ │ odc_admin │ │geoserver_ │
   └────┬─────┘ └────┬─────┘ └─────┬──────┘ └─────┬─────┘ │   app     │
        └────────────┴─────┬───────┴──────────────┘       └─────┬─────┘
                    ┌──────▼─────────────── desa-db ─────────────▼──────┐
                    │  datacube (ODC index + cubedash)  geoserver_vector │
                    └──────────────────────┬─────────────────────────────┘
                                   desa-db-backup → ./backups (nightly)
```

## Roles

| Role | Database | Can do | Used by |
|---|---|---|---|
| `odc_admin` | datacube (owner) | everything in the ODC schema | `datacube system init`, `product add`, `dataset add`, `datacube-ows-update` |
| `odc_reader` | datacube | SELECT only (5 min statement timeout) | OWS, JupyterHub |
| `odc_explorer` | datacube | SELECT on ODC, owns `cubedash` | Explorer web + `cubedash-gen` |
| `geoserver_app` | geoserver_vector (owner) | its own DB only, no CONNECT to datacube | GeoServer |
| `postgres` | all | superuser | admin and backups only — no app uses it |

Tables `odc_admin` creates later (new products) are readable by
`odc_reader`/`odc_explorer` automatically via default privileges.

## Bring-up

```bash
docker network create desa-net                 # skip if it exists
cd desa-db
cp .env.example .env && nano .env              # every *_PASSWORD
docker compose up -d
docker compose logs -f desa-db                 # wait for "DESA init: done"
```

`initdb/01-desa-init.sh` runs **only on an empty volume**. To re-run it,
`docker compose down -v` (this deletes the data).

## Path A — migrate the existing index (recommended)

1. Copy host/port/db/user/password from the current `datacube.conf` into the
   `OLD_DB_*` lines in `.env`.
2. Pause anything that indexes into the old DB.
3. Test the connection, then migrate:
   ```bash
   ./scripts/migrate-from-remote.sh --dry-run
   ./scripts/migrate-from-remote.sh
   ```
   It dumps the old DB (read-only against it), restores into `datacube` as
   `odc_admin`, applies grants, and prints product/dataset counts **old vs
   new** — they must match.
4. Repoint the app stack (below), then regenerate Explorer summaries:
   `docker compose exec explorer cubedash-gen --init --all`
5. Delete the `OLD_DB_*` lines and the dump inside the container
   (`/var/lib/postgresql/data/migrate/`).

## Path B — fresh index

```bash
datacube -E admin system init                  # as odc_admin
./scripts/grant-odc-access.sh
datacube -E admin product add ...  &&  datacube -E admin dataset add ...
```

## Repoint the app stack

- `clients/datacube.conf.example` → replaces the old `datacube.conf`.
  The default env is read-only; indexing uses `-E admin`.
- `clients/desa-services.env.example` → OWS, Explorer and JupyterHub DB URLs.
- GeoServer: `POSTGRES_HOST: desa-db` (already set in
  `geoserver/docker-compose.geoserver.yaml`).
- Rebuild/restart OWS, Explorer and JupyterHub, then run
  `datacube-ows-update` as `odc_admin`.

## Verify

```bash
docker compose ps                                          # healthy
docker exec desa-db psql -U postgres -c '\l'               # datacube, geoserver_vector
docker exec -it <ows container> datacube system check      # points at desa-db
ls -lh backups/daily                                       # after 01:00
```

## Backups and restore

Nightly at 01:00 SAST: custom-format dumps of both databases, keeping
7 daily / 4 weekly / 6 monthly. Put `BACKUP_DIR` on a different disk.

```bash
docker compose exec desa-db-backup /backup.sh               # backup now
docker exec -i desa-db pg_restore -U postgres -d datacube --clean --if-exists \
  --role=odc_admin --no-owner < backups/daily/datacube-YYYYMMDD.dump
```

## Notes

- Port 5432 is **not** published. To reach it from pgAdmin/QGIS, uncomment
  `ports:` and bind to the server's internal IP only.
- `pg_dump` in this image is v16, so the old server must be Postgres 16 or
  older. The migration script checks this.
- Tuning defaults assume about 8 GB for the DB; halve the `PG_*` values on a
  dev laptop.
