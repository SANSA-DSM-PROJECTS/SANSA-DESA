#!/usr/bin/env bash
# =============================================================================
# Index DE Africa Landsat C2 Level-2 (Surface Reflectance + Surface Temperature)
# for NATIONAL South Africa coverage, then refresh datacube-ows spatial ranges.
#
# WHY THIS EXISTS
# ---------------
# The TerriaJS "Surface Reflectance" / "Surface Temperature" layers only showed
# Gauteng because only Gauteng Landsat scenes had been indexed into the ODC
# Postgres index. Nothing in the TerriaJS catalog or the OWS *.py config limits
# the extent -- datacube-ows advertises and serves exactly the footprints that
# are indexed. Indexing the full South-Africa bbox (below) fixes the coverage.
# Pixels themselves are streamed on demand from DE Africa's public S3 buckets,
# so this only adds dataset metadata to the index, not the imagery.
#
# WHAT IT DOES
#   1. Ensures the ls8_sr / ls9_sr / ls8_st / ls9_st products are registered.
#   2. Runs stac-to-dc against DE Africa's STAC, filtered to the SA bbox, for
#      each product, adding every matching scene to the ODC index.
#   3. Runs datacube-ows-update so the WMS GetCapabilities extent and the tiles
#      reflect the newly-indexed national footprint.
#
# PREREQUISITES
#   - The compose stack is up (`docker compose up -d`) so desa-postgres and
#     desa-ows are running and reachable on the compose network.
#   - .env at the repo root is filled in (PGDB_* at minimum).
#   - Docker can pull opendatacube/datacube-index (has datacube + stac-to-dc).
#
# USAGE
#   cd desa-ows && ./index_landsat_sa.sh
#
# Override any of these on the command line, e.g.:
#   SA_BBOX='16,-35,33,-22' START_DATE=2020-01-01 ./index_landsat_sa.sh
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration (override via environment)
# ---------------------------------------------------------------------------
# South Africa mainland bounding box: left,bottom,right,top (lon/lat, EPSG:4326).
# Generous margins so no coastal/border scene is clipped; neighbouring overlap
# is harmless (OWS only serves what a request asks for).
SA_BBOX="${SA_BBOX:-16,-35,33,-22}"

# Landsat 8 has data from 2013; Landsat 9 from late 2021. A single START_DATE
# covering both is simplest; narrow it if you only want recent scenes.
START_DATE="${START_DATE:-2013-01-01}"
END_DATE="${END_DATE:-$(date +%F)}"

# DE Africa public STAC API root.
STAC_URL="${STAC_URL:-https://explorer.digitalearth.africa/stac}"

# Products to index. These names match both the DE Africa STAC collection ids
# and the product_name in the OWS layer configs / TerriaJS catalog.
PRODUCTS=(ls8_sr ls9_sr ls8_st ls9_st)

# Docker image with datacube + odc-apps-dc-tools (stac-to-dc, datacube CLI).
INDEX_IMAGE="${INDEX_IMAGE:-opendatacube/datacube-index:latest}"

# ---------------------------------------------------------------------------
# Resolve paths, env, and the compose network
# ---------------------------------------------------------------------------
# Windows Git Bash (MSYS) rewrites POSIX-looking arguments into Windows paths,
# which corrupts container-side paths like /products and DB URLs passed to
# `docker`. Disable that conversion. Both vars are MSYS-only and ignored on
# Linux/macOS, so this is safe everywhere.
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"

# Docker on Windows needs a Windows-style source path for bind mounts. On Git
# Bash, cygpath -m yields e.g. C:/Users/.../products (mixed slashes, which
# Docker Desktop accepts). On Linux there is no cygpath and the POSIX path is
# used as-is.
PRODUCTS_SRC="${SCRIPT_DIR}/products"
if command -v cygpath >/dev/null 2>&1; then
  PRODUCTS_SRC="$(cygpath -m "${PRODUCTS_SRC}")"
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: ${ENV_FILE} not found. Copy example.env to .env and fill it in." >&2
  exit 1
fi

# Load PGDB_* (and anything else) from .env without leaking to the log.
set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${PGDB_HOSTNAME:?PGDB_HOSTNAME must be set in .env}"
: "${PGDB_USERNAME:?PGDB_USERNAME must be set in .env}"
: "${PGDB_PASSWORD:?PGDB_PASSWORD must be set in .env}"
: "${PGDB_DATABASE:?PGDB_DATABASE must be set in .env}"

# Discover the compose network the postgres container is attached to, so the
# indexer can resolve ${PGDB_HOSTNAME}. Falls back to the default naming.
PROJECT_DEFAULT="$(basename "${REPO_ROOT}")"
NETWORK="${DESA_NETWORK:-}"
if [[ -z "${NETWORK}" ]]; then
  NETWORK="$(docker network ls --format '{{.Name}}' | grep -E "${PROJECT_DEFAULT}.*desa-network" | head -n1 || true)"
fi
if [[ -z "${NETWORK}" ]]; then
  NETWORK="$(docker network ls --format '{{.Name}}' | grep -E 'desa-network' | head -n1 || true)"
fi
if [[ -z "${NETWORK}" ]]; then
  echo "ERROR: could not find the desa-network docker network. Is the stack up?" >&2
  echo "       Set DESA_NETWORK=<name> explicitly (see: docker network ls)." >&2
  exit 1
fi

echo "==> Using docker network: ${NETWORK}"
echo "==> Target DB:            ${PGDB_DATABASE} @ ${PGDB_HOSTNAME}"
echo "==> SA bbox:              ${SA_BBOX}"
echo "==> Date range:           ${START_DATE} .. ${END_DATE}"
echo "==> Products:             ${PRODUCTS[*]}"
echo

# Helper: run a datacube/stac command inside a transient indexer container that
# shares the compose network and the ODC DB connection env.
dc() {
  docker run --rm \
    --network "${NETWORK}" \
    -e DB_HOSTNAME="${PGDB_HOSTNAME}" \
    -e DB_USERNAME="${PGDB_USERNAME}" \
    -e DB_PASSWORD="${PGDB_PASSWORD}" \
    -e DB_DATABASE="${PGDB_DATABASE}" \
    -e DB_PORT=5432 \
    -e DATACUBE_DB_URL="postgresql://${PGDB_USERNAME}:${PGDB_PASSWORD}@${PGDB_HOSTNAME}:5432/${PGDB_DATABASE}" \
    -e AWS_NO_SIGN_REQUEST=YES \
    -e AWS_DEFAULT_REGION="${AWS_REGION:-af-south-1}" \
    -v "${PRODUCTS_SRC}:/products:ro" \
    "${INDEX_IMAGE}" \
    "$@"
}

# ---------------------------------------------------------------------------
# 1. Ensure products are registered (idempotent; --update is a no-op if same)
# ---------------------------------------------------------------------------
echo "==> Registering / updating product definitions"
for p in "${PRODUCTS[@]}"; do
  echo "    - ${p}"
  dc datacube product add "/products/${p}.odc-product.yaml" || \
    dc datacube product update "/products/${p}.odc-product.yaml"
done
echo

# ---------------------------------------------------------------------------
# 2. Index scenes for the SA bbox, per product
# ---------------------------------------------------------------------------
for p in "${PRODUCTS[@]}"; do
  echo "==> Indexing ${p} for South Africa (${START_DATE} .. ${END_DATE})"
  dc stac-to-dc \
    --catalog-href="${STAC_URL}" \
    --collections="${p}" \
    --bbox="${SA_BBOX}" \
    --datetime="${START_DATE}/${END_DATE}"
  echo
done

# ---------------------------------------------------------------------------
# 3. Refresh datacube-ows spatial ranges (run inside the live OWS container)
# ---------------------------------------------------------------------------
echo "==> Refreshing datacube-ows ranges (materialised views + per-layer)"
# Run compose from the repo dir (avoids passing a Windows path to -f).
( cd "${REPO_ROOT}" && docker compose exec -T desa-ows datacube-ows-update --views )
for p in "${PRODUCTS[@]}"; do
  ( cd "${REPO_ROOT}" && docker compose exec -T desa-ows datacube-ows-update "${p}" )
done

echo
echo "==> Done. Verify with GetCapabilities:"
echo "    https://desadev-map.sansa.org.za/wms?service=WMS&request=GetCapabilities"
echo "    Check the <BoundingBox> for ls8_sr/ls9_sr/ls8_st/ls9_st now spans South Africa."
