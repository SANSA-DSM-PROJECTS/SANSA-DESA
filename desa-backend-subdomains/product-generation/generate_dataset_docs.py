#!/usr/bin/env python3
"""
DESA Water Quality -- Generate EO3 dataset documents for new months only.

First stage of the monthly automation pipeline:

    generate_dataset_docs.py        (this script: source COGs -> dataset docs)
      -> reindex_dst_water_indeces.sh      (dataset docs -> ODC index + Explorer)
      -> refresh_ows_dst_water_indeces.sh  (ODC index -> OWS ranges)

Only generates a document for a month if one doesn't already exist in the
lake bucket -- comparing against desa-products is what makes this safe to
run every month (or every day) without recreating existing docs.

Unlike a naive "assume all 7 bands exist" approach, this checks each band's
COG individually before building a document for a month. The ODC product
(dst_water_indeces) declares all 7 measurements and `datacube dataset add`
*rejects* (hard error, not a warning) any dataset missing a declared
measurement -- so a month isn't ready to index until every band exists. As
of 2026-10, the TDS index has a gap (no COG since 2026-04), so recent months
are correctly held back here rather than producing a document that would
fail indexing, or worse, index with a dangling path that 404s the first
time anything actually reads the `tds` band.

Usage:
  python3 generate_dataset_docs.py
"""

import os
import re
import sys
import uuid
import yaml
import rasterio
import boto3
from calendar import monthrange
from datetime import datetime


# ═══════════════════════════════════════════════════════════════
#  CONFIGURATION
# ═══════════════════════════════════════════════════════════════

MINIO_ENDPOINT = os.environ.get("AWS_S3_ENDPOINT", "10.150.16.133:9000")
MINIO_ACCESS_KEY = os.environ.get("MINIO_ACCESS_KEY")
MINIO_SECRET_KEY = os.environ.get("MINIO_SECRET_KEY")
MINIO_USE_HTTPS = os.environ.get("MINIO_USE_HTTPS", "no").lower() in ("yes", "true", "1")

if not MINIO_ACCESS_KEY or not MINIO_SECRET_KEY:
    raise SystemExit(
        "MINIO_ACCESS_KEY and MINIO_SECRET_KEY must be set in the environment."
    )

SOURCE_BUCKET = "eo-rad"
SOURCE_BASE = (
    "02_DST_PROGRAMMES/Water_Management_DST/"
    "04_PRODUCTS/decision_support_tools/Water"
)

LAKE_BUCKET = "desa-products"
PRODUCT_NAME = "dst_water_indeces"
PRODUCT_VERSION = "1-0-0"
LAKE_BASE = f"desa/products/{PRODUCT_NAME}/{PRODUCT_VERSION}/datasets"

INDEX_TO_BAND = {
    "ABI": "abi",
    "AWEI": "awei",
    "FAI": "fai",
    "NDCI": "ndci",
    "NDTI": "ndti",
    "TDS": "tds",
    "TSS": "tss",
}

# GDAL/rasterio S3 credentials (vsis3 driver -- used only to read spatial
# metadata, once, from a reference COG)
os.environ["AWS_S3_ENDPOINT"] = MINIO_ENDPOINT
os.environ["AWS_ACCESS_KEY_ID"] = MINIO_ACCESS_KEY
os.environ["AWS_SECRET_ACCESS_KEY"] = MINIO_SECRET_KEY
os.environ["AWS_VIRTUAL_HOSTING"] = "FALSE"
os.environ["AWS_HTTPS"] = "YES" if MINIO_USE_HTTPS else "NO"

scheme = "https" if MINIO_USE_HTTPS else "http"
s3 = boto3.client(
    "s3",
    endpoint_url=f"{scheme}://{MINIO_ENDPOINT}",
    aws_access_key_id=MINIO_ACCESS_KEY,
    aws_secret_access_key=MINIO_SECRET_KEY,
)


# ═══════════════════════════════════════════════════════════════
#  STEP 1: Discover which months need a document
# ═══════════════════════════════════════════════════════════════

def discover_source_months():
    """Union of dates across all 7 index folders in eo-rad (not just ABI --
    a month should be considered 'available' if ANY band has a COG for it,
    since missing individual bands are handled per-document, not by
    skipping the whole month)."""
    dates = set()
    paginator = s3.get_paginator("list_objects_v2")
    for folder in INDEX_TO_BAND:
        for page in paginator.paginate(
            Bucket=SOURCE_BUCKET, Prefix=f"{SOURCE_BASE}/{folder}/"
        ):
            for obj in page.get("Contents", []):
                m = re.search(rf"{folder}_(\d{{4}}-\d{{2}})-\d{{2}}\.tif$", obj["Key"])
                if m:
                    dates.add(m.group(1))
    return dates


def discover_existing_doc_months():
    """Months that already have a dataset document in the lake bucket."""
    months = set()
    paginator = s3.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=LAKE_BUCKET, Prefix=f"{LAKE_BASE}/"):
        for obj in page.get("Contents", []):
            m = re.search(
                rf"{PRODUCT_NAME}_(\d{{4}}-\d{{2}})\.odc-metadata\.yaml$", obj["Key"]
            )
            if m:
                months.add(m.group(1))
    return months


# ═══════════════════════════════════════════════════════════════
#  STEP 2: Spatial metadata (read once -- stable across the whole archive)
# ═══════════════════════════════════════════════════════════════

def get_spatial_metadata(year_month):
    path = f"s3://{SOURCE_BUCKET}/{SOURCE_BASE}/NDCI/NDCI_{year_month}-01.tif"
    with rasterio.Env():
        with rasterio.open(path) as src:
            return {
                "crs": str(src.crs),
                "bounds": src.bounds,
                "shape": list(src.shape),
                "transform": [
                    src.transform.a, src.transform.b, src.transform.c,
                    src.transform.d, src.transform.e, src.transform.f,
                    0, 0, 1,
                ],
            }


# ═══════════════════════════════════════════════════════════════
#  STEP 3: Build + upload dataset document
# ═══════════════════════════════════════════════════════════════

def band_exists(folder_name, year_month):
    key = f"{SOURCE_BASE}/{folder_name}/{folder_name}_{year_month}-01.tif"
    try:
        s3.head_object(Bucket=SOURCE_BUCKET, Key=key)
        return True
    except Exception:
        return False


def missing_bands(year_month):
    """Bands with no COG for this month. A non-empty result means the
    month isn't ready to index yet (ODC requires every declared
    measurement to be present)."""
    return [
        band_name
        for folder_name, band_name in INDEX_TO_BAND.items()
        if not band_exists(folder_name, year_month)
    ]


def build_dataset_document(year_month, spatial):
    year, month = year_month.split("-")
    _, last_day = monthrange(int(year), int(month))

    measurements = {
        band_name: {
            "path": (
                f"s3://{SOURCE_BUCKET}/{SOURCE_BASE}/"
                f"{folder_name}/{folder_name}_{year_month}-01.tif"
            )
        }
        for folder_name, band_name in INDEX_TO_BAND.items()
    }

    b = spatial["bounds"]
    geometry = {
        "type": "Polygon",
        "coordinates": [[
            [b.left, b.bottom],
            [b.left, b.top],
            [b.right, b.top],
            [b.right, b.bottom],
            [b.left, b.bottom],
        ]],
    }

    doc = {
        "$schema": "https://schemas.opendatacube.org/dataset",
        "id": str(uuid.uuid5(uuid.NAMESPACE_URL, f"dst-wq-{year_month}-01")),
        "product": {"name": PRODUCT_NAME},
        "crs": spatial["crs"],
        "geometry": geometry,
        "grids": {
            "default": {
                "shape": spatial["shape"],
                "transform": spatial["transform"],
            }
        },
        "properties": {
            "datetime": f"{year}-{month}-15T00:00:00Z",
            "dtr:start_datetime": f"{year}-{month}-01T00:00:00Z",
            "dtr:end_datetime": f"{year}-{month}-{last_day}T23:59:59Z",
            "odc:processing_datetime": datetime.utcnow().isoformat() + "Z",
            "odc:file_format": "GeoTIFF",
        },
        "measurements": measurements,
        "lineage": {},
    }
    return doc


def upload_to_lake(document, year_month):
    year, month = year_month.split("-")
    s3_key = (
        f"{LAKE_BASE}/{year}/{month}/"
        f"{PRODUCT_NAME}_{year_month}.odc-metadata.yaml"
    )
    yaml_content = yaml.dump(document, default_flow_style=False, sort_keys=False)
    s3.put_object(
        Bucket=LAKE_BUCKET,
        Key=s3_key,
        Body=yaml_content.encode("utf-8"),
        ContentType="application/x-yaml",
    )
    return f"s3://{LAKE_BUCKET}/{s3_key}"


# ═══════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print(f"[{datetime.utcnow().isoformat()}Z] Discovering source months in eo-rad...")
    source_months = discover_source_months()
    existing_months = discover_existing_doc_months()
    new_months = sorted(source_months - existing_months)

    print(f"  source months (any band present): {len(source_months)}")
    print(f"  existing dataset documents:       {len(existing_months)}")
    print(f"  new months needing a document:    {len(new_months)}")

    if not new_months:
        print("Nothing to do -- every source month already has a dataset document.")
        sys.exit(0)

    print(f"\nCandidate months: {new_months}")

    ready_months = []
    held_back = {}
    for year_month in new_months:
        missing = missing_bands(year_month)
        if missing:
            held_back[year_month] = missing
        else:
            ready_months.append(year_month)

    if held_back:
        print("\nHeld back (incomplete -- not every band has a COG yet):")
        for year_month, missing in held_back.items():
            print(f"  {year_month}: missing {missing}")

    if not ready_months:
        print("\nNo complete new months to index yet.")
        sys.exit(0)

    print(f"\nReady to generate: {ready_months}")
    print("\nReading reference spatial metadata...")
    spatial = get_spatial_metadata(ready_months[0])
    print(f"  CRS: {spatial['crs']}  shape: {spatial['shape']}")

    for year_month in ready_months:
        doc = build_dataset_document(year_month, spatial)
        s3_uri = upload_to_lake(doc, year_month)
        print(f"  created {s3_uri}")

    print(f"\nDone: {len(ready_months)} new dataset document(s) created, {len(held_back)} held back.")
