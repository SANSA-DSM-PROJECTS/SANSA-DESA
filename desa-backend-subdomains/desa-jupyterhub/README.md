# EO JupyterHub (Earth Observation + Open Data Cube)

Multi-user JupyterHub for Earth Observation workflows:
- **NativeAuthenticator** — users self-register, admin approves in the UI.
- **DockerSpawner** — each user gets their own container + persistent volume.
- **Postgres** — hub state.
- **PostGIS `datacube-db`** — Open Data Cube index; `DATACUBE_DB_URL` is injected
  into every user container (no per-user `~/.datacube.conf` needed).
- **EO singleuser image** — SciPy/ML stack plus GDAL, rasterio, rioxarray, xarray,
  dask, geopandas, cartopy, stackstac, pystac-client, odc-stac, odc-geo,
  **datacube**, odc-apps-dc-tools, leafmap, eodag, sentinelhub.

Run `datacube system init` once against `datacube-db` to create the index schema,
then index products with `stac-to-dc` / `s3-to-dc`.

## Layout
```
desa-jupyterhub/
├── docker-compose.yml
├── .env.example
├── hub/
│   ├── Dockerfile
│   └── jupyterhub_config.py
└── singleuser/
    └── Dockerfile
```

## First run
```bash
cp .env.example .env
# edit .env, at minimum set POSTGRES_PASSWORD and JUPYTERHUB_ADMIN_USERS

# Build the singleuser image (big — ML + geo). Do this first, hub needs it present.
docker compose --profile build-only build singleuser

# Bring up hub + db
docker compose up -d --build hub hub-db
```

Open `http://<host>:8000`, click **Sign up**, register the username you listed in `JUPYTERHUB_ADMIN_USERS`. That account is auto-approved and admin. Other signups appear under `/hub/authorize` for the admin to approve.

## Put TLS in front of it
This compose exposes plain HTTP on `:8000`. In production, front it with nginx / Traefik / Caddy terminating TLS to `hub:8000`.

## Notes
- The `singleuser` service in `docker-compose.yml` uses `profiles: ["build-only"]` so `docker compose up` never tries to *run* it — DockerSpawner launches user containers on demand from the built image.
- User homes persist in named volumes `jupyterhub-user-<username>`.
- `mem_limit` / `cpu_limit` in `jupyterhub_config.py` are per-user — tune to your host.
- For GPU users, fork `singleuser/Dockerfile` to use `nvidia/cuda` + GPU wheels, and add `runtime: nvidia` to the spawner config.
