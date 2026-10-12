# DESA — Digital Earth South Africa

Backend stack for the Digital Earth South Africa (DESA) platform, operated by
the South African National Space Agency (SANSA).

DESA is an [Open Data Cube](https://www.opendatacube.org/) (ODC) deployment:
satellite and derived Earth-observation products are indexed into a PostGIS
database and published as OGC web services (WMS / WCS / WMTS), an interactive
map, a data explorer, and a JupyterHub analysis environment.

---

## Architecture

All services sit behind a single nginx reverse proxy that terminates TLS and
routes by subdomain.

```
                          ┌──────────────────────┐
   *.sansa.org.za  ──────▶│   desa-nginx  :443   │
                          └───────────┬──────────┘
              ┌───────────────┬───────┴───────┬────────────────┐
              ▼               ▼               ▼                ▼
     desadev.…        desadev-ows.…   desadev-map.…    desadev-explorer.…
     (static UI)      datacube-ows     TerriaMap        ODC Explorer
      desa-ui           :8000            :3001              :8080
                            │                                  │
                            └──────────────┬───────────────────┘
                                           ▼
                              PostgreSQL / PostGIS  (ODC index)
                                           ▲
                                           │
                              desadev-hub.…│  JupyterHub :8000
                                           │
                              ┌────────────┴────────────┐
                              │  MinIO data lake (COGs) │
                              │    10.150.16.133:9000   │
                              └─────────────────────────┘
```

| Subdomain | Service | Container |
|---|---|---|
| `desadev.sansa.org.za` | Static marketing / portal UI | `desa-nginx` → `desa-ui/` |
| `desadev-ows.sansa.org.za` | OGC web services (WMS/WCS/WMTS) | `desa-ows` |
| `desadev-map.sansa.org.za` | TerriaMap interactive map | `map` |
| `desadev-explorer.sansa.org.za` | ODC Explorer (dataset browser) | `explorer` |
| `desadev-hub.sansa.org.za` | JupyterHub sandbox | `jupyterhub` |

### Repository layout

| Path | Purpose |
|---|---|
| `desa-ows/` | datacube-ows config — layer definitions, styles, product YAMLs |
| `desa-terriamap/` | TerriaMap overlay — Dockerfile + `wwwroot/` overrides only |
| `desa-ui/` | Static portal frontend |
| `desa-jupyterhub/` | JupyterHub image, config, and example notebooks |
| `nginx/` | Reverse-proxy config and (gitignored) TLS material |
| `product-generation/` | Scripts to build and index new ODC products |

---

## Setup

### Prerequisites

- Docker + Docker Compose
- Network access to the ODC PostgreSQL database and the MinIO data lake
- TLS certificate and key (see `nginx/ssl/README.md`)

### 1. Configure environment

```bash
cp example.env .env
# edit .env with real values
```

`.env` is gitignored and must never be committed. See `example.env` for what
each variable does.

### 2. Provide TLS certificates

Place the certificate, key, and CA bundle in `nginx/ssl/` — see
[`nginx/ssl/README.md`](nginx/ssl/README.md).

### 3. Bring up the stack

```bash
docker compose up -d
```

---

## Publishing a new product to OWS

Adding a product to the map is a **four-step** process. Steps 3 and 4 are the
ones most often missed — the layer will silently fail to appear without them.

### 1. Index the product into the datacube

```bash
datacube product add product-generation/<product>.yaml
python product-generation/generate_and_store_datasets.py
datacube dataset add dataset_docs/*.yaml
datacube dataset count -p <product>          # verify
```

### 2. Add the OWS layer config

Create a domain folder under `desa-ows/services/ows_refactored/` following the
existing convention (see `wofs/` or `water_quality/` as templates):

- `band_<product>_cfg.py` — band/measurement definitions (`bands_*`)
- `styles_<product>.py` — colour ramps and styles (`style_*`)
- `ows_<product>_cfg.py` — the `layer` dict tying them together

Then include it in the catalog tree in `dev_af_ows_root_cfg.py` and
`prod_af_ows_root_cfg.py`:

```python
{
    "title": "My Category",
    "abstract": """My Category""",
    "layers": [
        {
            "include": "ows_refactored.<domain>.ows_<product>_cfg.layer",
            "type": "python",
        },
    ],
},
```

### 3. Publish the product's native CRS ⚠️

**A layer whose `native_crs` is not listed in `published_CRSs` is dropped
entirely** — it will not appear in `GetCapabilities`, with only an error in the
container log. Add it to the `global.published_CRSs` block in *both* root
configs:

```python
"EPSG:32735": {  # WGS 84 / UTM zone 35S
    "geographic": False,
    "horizontal_coord": "x",
    "vertical_coord": "y",
},
```

### 4. Build the OWS range tables ⚠️

datacube-ows caches each layer's spatial and temporal extents. Until this runs,
the layer reports `Null product range` and is not served:

```bash
docker exec <ows-container> datacube-ows-update --views      # refresh matviews
docker exec <ows-container> datacube-ows-update <product>    # compute ranges
docker compose restart desa-ows
```

`--views` is required whenever a *newly indexed* product is added; without it
the range update fails with "materialised views are most likely missing a newly
indexed product".

### 5. Verify

```bash
curl -s "http://localhost:8000/wms?service=WMS&version=1.3.0&request=GetCapabilities" \
  | grep -c "<product-name>"
```

Then add it to the TerriaMap catalog in
`desa-terriamap/wwwroot/init/simple.json`.

---

## TerriaMap

`desa-terriamap/` is a **thin overlay**, not a full TerriaMap checkout. The
Dockerfile builds `FROM ghcr.io/terriajs/terriamap` and copies in only the DESA
customisations (`wwwroot/config.json`, `wwwroot/init/simple.json`, branding
images). Rebuilds are therefore fast — there is no `yarn build` step.

> **`wwwroot/` is baked into the image at build time** — there is no volume
> mount. Editing a config file on the host has no effect until you rebuild:
>
> ```bash
> docker compose up -d --build desa-terriamap
> ```

### Basemaps

Basemaps are defined in the `baseMaps` block of `wwwroot/init/simple.json`.
Note the TerriaJS v8 schema — `defaultBaseMapId` and `previewBaseMapId` live
*inside* `baseMaps`, not at the file root:

```json
"baseMaps": {
  "defaultBaseMapId": "basemap-positron",
  "previewBaseMapId": "basemap-positron",
  "items": [ ... ]
}
```

Both IDs must match an `id` present in `items`, otherwise the setting is
silently ignored. Bing basemaps are **not** available unless `bingMapsKey` or
`useCesiumIonBingImagery` is set in `config.json`.

---

## Object storage

Products are read from an on-prem MinIO data lake over the S3 protocol. GDAL
reaches it via `AWS_S3_ENDPOINT` with path-style addressing and signed
requests.

> **Caveat:** GDAL's S3 settings are **global per container**. A single
> `desa-ows` instance cannot simultaneously read unsigned public AWS buckets
> and the signed private MinIO bucket. If DE Africa products hosted on public
> AWS S3 are ever indexed alongside local products, this needs a per-bucket
> solution (separate OWS instances, or GDAL config-file profiles) rather than
> the current global override.

---

## Troubleshooting

| Symptom | Cause |
|---|---|
| `GetCapabilities` returns no `<Layer>` elements | Every layer failed to load — check container logs; each layer fails independently |
| `Native CRS ... not in published CRSs` | Add the CRS to `published_CRSs` (step 3 above) |
| `get_ranges failed: Null product range` | Run `datacube-ows-update` (step 4 above) |
| `Could not find product X in datacube` | Product not indexed in this database |
| `does not exist in the file system` on an `s3://` path | S3/MinIO credentials or endpoint misconfigured |
| Terria shows a layer but tiles are blank | Check the requested `time` is a valid dimension value |
| Terria config changes have no effect | `wwwroot/` is baked in — rebuild the image |

Container logs are the primary diagnostic:

```bash
docker logs <ows-container> --tail 100
```

---

## Security

- Secrets (`.env`, TLS keys, `datacube.conf`) are gitignored — see
  `.gitignore`. Never commit them.
- Templates (`example.env`, `datacube.conf.example`) are committed instead.
- If a private key is ever exposed, revoke and reissue the certificate —
  deleting the file does not remove it from git history.
