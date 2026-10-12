#!/usr/bin/env bash
# Render desa-ows/gdal-s3.conf from the repository-root .env
#
# gdal-s3.conf holds MinIO credentials, so it is gitignored and must be
# regenerated on each deployment (and after any credential rotation):
#
#     ./desa-ows/render-gdal-conf.sh && docker compose up -d desa-ows
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"
OUT="$ROOT/desa-ows/gdal-s3.conf"

[ -f "$ENV_FILE" ] || { echo "ERROR: $ENV_FILE not found (copy example.env to .env)" >&2; exit 1; }

get() { grep -E "^$1=" "$ENV_FILE" | head -1 | cut -d= -f2- ; }

EP="$(get AWS_S3_ENDPOINT)"
AK="$(get MINIO_ACCESS_KEY)"
SK="$(get MINIO_SECRET_KEY)"

for v in EP AK SK; do
  [ -n "${!v}" ] || { echo "ERROR: AWS_S3_ENDPOINT / MINIO_ACCESS_KEY / MINIO_SECRET_KEY must be set in .env" >&2; exit 1; }
done

cat > "$OUT" <<EOF
# GDAL per-path S3 configuration -- GENERATED, CONTAINS CREDENTIALS, GITIGNORED.
# Regenerate with: ./desa-ows/render-gdal-conf.sh   (reads repo-root .env)
#
# Why this file exists: GDAL's S3 settings are global per process, but desa-ows
# must read from two incompatible object stores at once --
#   * Digital Earth Africa public buckets on real AWS  (unsigned, HTTPS, virtual-hosted)
#   * the SANSA MinIO data lake                        (signed, HTTP, path-style)
# Global env is set for the AWS case; the section below overrides it for MinIO
# paths only. AWS_NO_SIGN_REQUEST=NO here is essential -- without it the global
# unsigned setting wins and MinIO returns 403.
[credentials]

[.credentials.minio_datalake]
path=/vsis3/eo-rad
AWS_S3_ENDPOINT=$EP
AWS_HTTPS=NO
AWS_VIRTUAL_HOSTING=FALSE
AWS_NO_SIGN_REQUEST=NO
AWS_ACCESS_KEY_ID=$AK
AWS_SECRET_ACCESS_KEY=$SK
EOF

chmod 600 "$OUT"
echo "Wrote $OUT"
