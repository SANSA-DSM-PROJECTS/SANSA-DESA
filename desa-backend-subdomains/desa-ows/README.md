# desa-ows — Digital Earth South Africa OGC Web Services

`datacube-ows` serves the DESA raster layers (WMS / WMTS / WCS) that the
TerriaMap catalog and Explorer consume. It reads dataset **metadata** from the
Open Data Cube (ODC) Postgres index (`desa-postgres`) and streams the actual
**pixels** on demand from S3 — DE Africa's public buckets for the Landsat
products, and the on-prem MinIO data lake for locally generated products.

Runs as the `desa-ows` service in the repo-root `docker-compose.yaml`
(image `opendatacube/ows:1.8.0-rc1`), behind nginx at
`https://desadev-map.sansa.org.za/wms`.

## Layout

| Path | What it is |
|------|------------|
| `products/*.odc-product.yaml` | ODC product definitions (band specs, metadata type). Mounted at `/products`. |
| `services/ows_refactored/` | The OWS config package (`DATACUBE_OWS_CFG=ows_refactored.dev_af_ows_root_cfg.ows_cfg`). See `services/ows_refactored/README.md`. |
| `services/ows_refactored/<theme>/ows_*_cfg.py` | Per-layer configs (bands, styles, resource limits). |
| `services/ows_refactored/*_ows_root_cfg.py` | Root assembler — the layer tree exposed by the service (`dev_af` / `prod_af`). |
| `services/inventory/` | Generated inventory of layers + styles. |
| `index_landsat_sa.sh` | Indexes Landsat SR/ST for national South Africa coverage (see below). |
| `gdal-s3.conf` | Rendered by `render-gdal-conf.sh` from `.env`; per-path GDAL S3 settings. Gitignored. |

## How a layer's geographic extent is determined

**Important:** a layer's advertised and served extent is **not** set in the
TerriaMap catalog (`desa-terriamap/wwwroot/init/simple.json`) or in the OWS
`*.py` config. datacube-ows computes it from the **spatial ranges of the
datasets actually indexed** into the Postgres index, cached in the OWS
materialised views.

Consequence: if a layer only shows part of the country, it is because only that
region's scenes have been indexed. Widening coverage is an **indexing**
operation, not a config edit — index the additional scenes, then refresh the
OWS ranges.

## National South Africa coverage for Surface Reflectance / Surface Temperature

### Background

The TerriaMap "Surface Reflectance" (`ls8_sr`, `ls9_sr`) and "Surface
Temperature" (`ls8_st`, `ls9_st`) layers originally rendered only over Gauteng
because only Gauteng Landsat scenes had been indexed. Nothing in the catalog or
OWS config restricted the extent. To get national coverage, index the full
South-Africa bounding box and refresh the OWS ranges.

### The script: `index_landsat_sa.sh`

Idempotent, three steps:

1. **Register** the `ls8_sr` / `ls9_sr` / `ls8_st` / `ls9_st` products from
   `products/*.odc-product.yaml` (`datacube product add`, falling back to
   `update`).
2. **Index** every DE Africa Landsat C2 Level-2 scene inside the South-Africa
   bbox via `stac-to-dc` against DE Africa's public STAC. Only metadata is
   indexed; imagery stays in DE Africa S3 and is streamed on request.
3. **Refresh** datacube-ows ranges (`datacube-ows-update --views`, then per
   layer) so GetCapabilities and the tiles reflect the new national footprint.

It runs the indexer as a transient `opendatacube/datacube-index` container
attached to the compose network (so it can reach `desa-postgres`), reads DB
credentials from the repo-root `.env`, and auto-detects the network name.

### Prerequisites

- The stack is up: `docker compose up -d` (so `desa-postgres` and `desa-ows`
  are running and on the network).
- The repo-root `.env` is filled in — at minimum `PGDB_HOSTNAME`,
  `PGDB_USERNAME`, `PGDB_PASSWORD`, `PGDB_DATABASE`.
- Docker can pull `opendatacube/datacube-index` (provides `datacube` +
  `stac-to-dc`).

### Usage

```bash
docker compose up -d          # if not already running
cd desa-ows
./index_landsat_sa.sh
```

### Configuration (override via environment)

| Variable | Default | Meaning |
|----------|---------|---------|
| `SA_BBOX` | `16,-35,33,-22` | `left,bottom,right,top` (lon/lat, EPSG:4326). Generous margins so no coastal/border scene is clipped. |
| `START_DATE` | `2013-01-01` | Earliest scene date. LS8 → 2013, LS9 → late 2021. |
| `END_DATE` | today | Latest scene date. |
| `STAC_URL` | `https://explorer.digitalearth.africa/stac` | DE Africa STAC API root. |
| `INDEX_IMAGE` | `opendatacube/datacube-index:latest` | Image with `datacube` + `stac-to-dc`. |
| `DESA_NETWORK` | auto-detected | Compose network name (override if detection fails; see `docker network ls`). |

Examples:

```bash
# Recent scenes only (fast test)
START_DATE=2023-01-01 ./index_landsat_sa.sh

# Tighter box, explicit network
SA_BBOX='16,-35,33,-22' DESA_NETWORK=desa-backend-subdomains_desa-network ./index_landsat_sa.sh
```

### Verify

After it finishes, check WMS GetCapabilities — the `<BoundingBox>` for
`ls8_sr` / `ls9_sr` / `ls8_st` / `ls9_st` should now span South Africa:

```
https://desadev-map.sansa.org.za/wms?service=WMS&request=GetCapabilities
```

The TerriaMap layers then render nationally with **no catalog change** needed.

### Notes

- National LS8+LS9 SR+ST from 2013→present is a large number of scenes.
  Indexing metadata is fast but not instant — narrow `START_DATE` for a quick
  first run.
- `ls8_st` / `ls9_st` are distinct DE Africa STAC collections from their `_sr`
  counterparts; the script indexes all four separately.
- Re-running is safe: product registration and `stac-to-dc` skip/annotate
  already-indexed datasets, and the range refresh is always recomputed.

## Related

- Locally generated products (e.g. `dst_water_indeces`) are built and pushed to
  MinIO by `../product-generation/generate_and_store_datasets.py`, then indexed
  with `datacube dataset add`.
- OWS config conventions: `services/ows_refactored/README.md`.
