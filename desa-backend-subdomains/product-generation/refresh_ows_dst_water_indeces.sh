#!/bin/sh
# Refreshes OWS materialised views + ranges for dst_water_indeces after new
# datasets have been indexed (see reindex_dst_water_indeces.sh, which must
# run first -- in desa-explorer -- so the new datasets exist to pick up).
#
# Runs inside the desa-ows container (datacube-ows-update lives there, not
# in desa-explorer) via the Ofelia scheduler defined in docker-compose.yaml.
set -eu

PRODUCT_NAME="dst_water_indeces"

log() { echo "[$(date -u +%FT%TZ)] $*"; }

log "Refreshing OWS materialised views"
datacube-ows-update --views

log "Refreshing OWS ranges for ${PRODUCT_NAME}"
datacube-ows-update "$PRODUCT_NAME"

log "Done."
