#!/bin/sh
# Monthly reindex for dst_water_indeces.
#
# Pipeline (each stage idempotent on its own):
#   1. generate_dataset_docs.py -- scan eo-rad for months with no dataset
#      document yet in the lake bucket, and create one (skipping any band
#      whose COG doesn't exist for that month, rather than writing a
#      dangling path).
#   2. List every dataset document currently in the lake bucket and pass
#      their s3:// URLs straight to `datacube dataset add` -- no local
#      download. ODC skips any dataset whose id is already indexed (logged
#      as a warning, not an error), so this is a no-op for months indexed
#      in a previous run.
#   3. Refresh Explorer's cubedash summary for the product.
#
# Intended to run inside the desa-explorer container (has datacube CLI,
# cubedash-gen, boto3, rasterio already installed) via the Ofelia scheduler
# defined in docker-compose.yaml. OWS has its own view/range refresh --
# see refresh_ows_dst_water_indeces.sh, run as a separate job in the
# desa-ows container (datacube-ows-update isn't installed here).
set -eu

PRODUCT_NAME="dst_water_indeces"
PRODUCT_VERSION="1-0-0"
LAKE_BUCKET="desa-products"
LAKE_PREFIX="desa/products/${PRODUCT_NAME}/${PRODUCT_VERSION}/datasets/"
SCRIPT_DIR="$(dirname "$0")"
URL_LIST="/tmp/reindex_${PRODUCT_NAME}_urls.txt"

log() { echo "[$(date -u +%FT%TZ)] $*"; }

log "Generating dataset documents for any new source months"
python3 "${SCRIPT_DIR}/generate_dataset_docs.py"

log "Listing dataset documents in s3://${LAKE_BUCKET}/${LAKE_PREFIX}"
# AWS_ENDPOINT_URL_S3 is the standard botocore env var for a custom S3
# endpoint (MinIO here) -- it's what makes `datacube dataset add s3://...`
# below talk to MinIO instead of real AWS. AWS_S3_ENDPOINT (GDAL's env var,
# used by generate_dataset_docs.py for rasterio) does nothing for boto3.
export AWS_ENDPOINT_URL_S3="http://${AWS_S3_ENDPOINT}"
export AWS_ACCESS_KEY_ID="${MINIO_ACCESS_KEY}"
export AWS_SECRET_ACCESS_KEY="${MINIO_SECRET_KEY}"

python3 - "$LAKE_BUCKET" "$LAKE_PREFIX" "$URL_LIST" <<'PYEOF'
import sys, boto3

bucket, prefix, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
s3 = boto3.client("s3")  # picks up AWS_ENDPOINT_URL_S3 / creds from env
paginator = s3.get_paginator("list_objects_v2")
count = 0
with open(out_path, "w") as f:
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get("Contents", []):
            key = obj["Key"]
            if key.endswith(".yaml"):
                f.write(f"s3://{bucket}/{key}\n")
                count += 1
print(f"found {count} dataset documents")
PYEOF

log "Indexing directly from S3 (already-indexed datasets are skipped, not duplicated)"
# datacube dataset add doesn't glob s3:// paths, so URLs are listed
# explicitly above and passed as positional args here.
xargs -a "$URL_LIST" datacube dataset add

log "Refreshing Explorer summaries for ${PRODUCT_NAME}"
cubedash-gen "$PRODUCT_NAME"

log "Done. Run refresh_ows_dst_water_indeces.sh in desa-ows next to update OWS ranges."
