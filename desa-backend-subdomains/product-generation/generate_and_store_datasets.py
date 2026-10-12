#!/usr/bin/env python3
"""
DESA Water Quality — Generate dataset documents and store on MinIO

This script:
  1. Scans eo-rad bucket to discover all available monthly COGs
  2. Reads spatial metadata from one sample COG
  3. Generates EO3 dataset documents for each month
  4. Uploads documents to eo-dsm bucket (data lake)
  5. Saves local copies for indexing via datacube CLI

Data Lake layout:
  s3://eo-dsm/                              ← data lake bucket
  └── desa/
      └── products/
          └── dst_water_indeces/
              └── 1-0-0/
                  └── datasets/
                      ├── 2017/
                      │   ├── 01/
                      │   │   └── dst_water_indeces_2017-01.odc-metadata.yaml
                      │   ├── 02/
                      │   │   └── dst_water_indeces_2017-02.odc-metadata.yaml
                      │   └── ...
                      ├── 2018/
                      └── ...

  Source COGs remain untouched in eo-rad:
  s3://eo-rad/02_DST_PROGRAMMES/.../Water/{INDEX}/{INDEX}_YYYY-MM-DD.tif

Usage:
  python generate_and_store_datasets.py
  datacube dataset add dataset_docs/*.yaml
"""

import os
import re
import uuid
import yaml
import rasterio
import boto3
from calendar import monthrange
from datetime import datetime


# ═══════════════════════════════════════════════════════════════
#  CONFIGURATION
# ═══════════════════════════════════════════════════════════════

# MinIO connection — credentials come from the environment, never hardcoded.
# Populate them from the repo-root .env (which is gitignored), e.g.:
#   export $(grep -v '^#' ../.env | xargs)
MINIO_ENDPOINT = os.environ.get("AWS_S3_ENDPOINT", "10.150.16.133:9000")
MINIO_ACCESS_KEY = os.environ.get("MINIO_ACCESS_KEY")
MINIO_SECRET_KEY = os.environ.get("MINIO_SECRET_KEY")
MINIO_USE_HTTPS = os.environ.get("MINIO_USE_HTTPS", "no").lower() in ("yes", "true", "1")

if not MINIO_ACCESS_KEY or not MINIO_SECRET_KEY:
    raise SystemExit(
        "MINIO_ACCESS_KEY and MINIO_SECRET_KEY must be set in the environment.\n"
        "See example.env at the repository root."
    )

# Source bucket — raw COGs (read only)
SOURCE_BUCKET = "eo-rad"
SOURCE_BASE = (
    "02_DST_PROGRAMMES/Water_Management_DST/"
    "04_PRODUCTS/decision_support_tools/Water"
)

# Data lake bucket — dataset documents (write)
LAKE_BUCKET = "desa-products"

# Product name — must match the registered ODC product exactly
PRODUCT_NAME = "dst_water_indeces"
PRODUCT_VERSION = "1-0-0"

# Path inside eo-dsm: desa/products/{product}/{version}/datasets/{year}/{month}/
LAKE_BASE = f"desa/products/{PRODUCT_NAME}/{PRODUCT_VERSION}/datasets"

# Index folder → ODC band name mapping
INDEX_TO_BAND = {
    "ABI":  "abi",
    "AWEI": "awei",
    "FAI":  "fai",
    "NDCI": "ndci",
    "NDTI": "ndti",
    "TDS":  "tds",
    "TSS":  "tss",
}


# ═══════════════════════════════════════════════════════════════
#  SETUP
# ═══════════════════════════════════════════════════════════════

# GDAL/rasterio S3 credentials
os.environ["AWS_S3_ENDPOINT"] = MINIO_ENDPOINT
os.environ["AWS_ACCESS_KEY_ID"] = MINIO_ACCESS_KEY
os.environ["AWS_SECRET_ACCESS_KEY"] = MINIO_SECRET_KEY
os.environ["AWS_VIRTUAL_HOSTING"] = "FALSE"
os.environ["AWS_HTTPS"] = "YES" if MINIO_USE_HTTPS else "NO"

# boto3 client
scheme = "https" if MINIO_USE_HTTPS else "http"
s3 = boto3.client(
    "s3",
    endpoint_url=f"{scheme}://{MINIO_ENDPOINT}",
    aws_access_key_id=MINIO_ACCESS_KEY,
    aws_secret_access_key=MINIO_SECRET_KEY,
)


# ═══════════════════════════════════════════════════════════════
#  STEP 1: Discover available dates
# ═══════════════════════════════════════════════════════════════

def discover_dates():
    """Scan ABI folder in eo-rad for all YYYY-MM-DD dates."""
    print("Discovering available dates from ABI folder...")

    dates = set()
    paginator = s3.get_paginator("list_objects_v2")

    for page in paginator.paginate(
        Bucket=SOURCE_BUCKET, Prefix=f"{SOURCE_BASE}/ABI/"
    ):
        for obj in page.get("Contents", []):
            match = re.search(r"ABI_(\d{4}-\d{2}-\d{2})\.tif$", obj["Key"])
            if match:
                dates.add(match.group(1))

    result = sorted(dates)
    print(f"  Found {len(result)} dates: {result[0]} → {result[-1]}")
    return result


# ═══════════════════════════════════════════════════════════════
#  STEP 2: Read spatial metadata from a COG
# ═══════════════════════════════════════════════════════════════

def get_spatial_metadata(date_str):
    """Read CRS, bounds, shape, transform from one source COG."""
    path = f"s3://{SOURCE_BUCKET}/{SOURCE_BASE}/NDCI/NDCI_{date_str}.tif"

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
#  STEP 3: Build dataset document
# ═══════════════════════════════════════════════════════════════

def build_dataset_document(date_str, spatial):
    """Build an EO3 dataset document for one month."""
    year, month, day = date_str.split("-")
    _, last_day = monthrange(int(year), int(month))

    # Measurement paths point to source COGs in eo-rad
    measurements = {}
    for folder_name, band_name in INDEX_TO_BAND.items():
        measurements[band_name] = {
            "path": (
                f"s3://{SOURCE_BUCKET}/{SOURCE_BASE}/"
                f"{folder_name}/{folder_name}_{date_str}.tif"
            )
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

    return {
        "$schema": "https://schemas.opendatacube.org/dataset",
        "id": str(uuid.uuid5(uuid.NAMESPACE_URL, f"dst-wq-{date_str}")),
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


# ═══════════════════════════════════════════════════════════════
#  STEP 4: Upload to eo-dsm and save locally
# ═══════════════════════════════════════════════════════════════

def upload_to_lake(document, date_str):
    """
    Upload the dataset document to the eo-dsm data lake bucket.

    Path: s3://desa-products/desa/products/dst_water_indeces/1-0-0/
              datasets/{year}/{month}/dst_water_indeces_{year}-{month}.odc-metadata.yaml
    """
    year, month, _ = date_str.split("-")

    s3_key = (
        f"{LAKE_BASE}/{year}/{month}/"
        f"{PRODUCT_NAME}_{year}-{month}.odc-metadata.yaml"
    )

    yaml_content = yaml.dump(document, default_flow_style=False, sort_keys=False)

    s3.put_object(
        Bucket=LAKE_BUCKET,
        Key=s3_key,
        Body=yaml_content.encode("utf-8"),
        ContentType="application/x-yaml",
    )

    return f"s3://{LAKE_BUCKET}/{s3_key}"


def save_local_copy(document, date_str, output_dir="dataset_docs"):
    """Save a local copy for indexing via datacube CLI."""
    os.makedirs(output_dir, exist_ok=True)
    year, month, _ = date_str.split("-")
    filepath = os.path.join(
        output_dir, f"{PRODUCT_NAME}_{year}-{month}.odc-metadata.yaml"
    )
    with open(filepath, "w") as f:
        yaml.dump(document, f, default_flow_style=False, sort_keys=False)
    return filepath


# ═══════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("=" * 60)
    print("  DESA Water Quality — Dataset Document Generation")
    print(f"  Product:      {PRODUCT_NAME}")
    print(f"  Version:      {PRODUCT_VERSION}")
    print(f"  Source:       s3://{SOURCE_BUCKET}/{SOURCE_BASE}/")
    print(f"  Data lake:    s3://{LAKE_BUCKET}/{LAKE_BASE}/")
    print("=" * 60)

    # 1. Discover dates
    dates = discover_dates()

    # 2. Read spatial metadata once
    print(f"\nReading spatial metadata from NDCI_{dates[0]}.tif...")
    spatial = get_spatial_metadata(dates[0])
    print(f"  CRS:    {spatial['crs']}")
    print(f"  Shape:  {spatial['shape']}")
    print(f"  Bounds: {spatial['bounds']}")

    # 3. Generate, upload, and save
    print(f"\nGenerating {len(dates)} dataset documents...")
    print()

    for date_str in dates:
        doc = build_dataset_document(date_str, spatial)
        s3_uri = upload_to_lake(doc, date_str)
        local_path = save_local_copy(doc, date_str)

        year, month, _ = date_str.split("-")
        print(f"  ✓ {year}-{month}  →  {s3_uri}")

    # 4. Summary
    print()
    print("=" * 60)
    print(f"  COMPLETE: {len(dates)} dataset documents")
    print("=" * 60)
    print()
    print("  Data lake (eo-dsm):")
    print(f"    s3://{LAKE_BUCKET}/")
    print(f"    └── desa/")
    print(f"        └── products/")
    print(f"            └── {PRODUCT_NAME}/")
    print(f"                └── {PRODUCT_VERSION}/")
    print(f"                    └── datasets/")
    print(f"                        ├── 2017/")
    print(f"                        │   ├── 01/")
    print(f"                        │   │   └── {PRODUCT_NAME}_2017-01.odc-metadata.yaml")
    print(f"                        │   └── ...")
    print(f"                        └── ...")
    print()
    print("  Local copies:")
    print(f"    dataset_docs/")
    print()
    print("  To index into ODC:")
    print(f"    datacube dataset add dataset_docs/*.yaml")
    print()
    print("  To verify:")
    print(f"    datacube dataset count -p {PRODUCT_NAME}")
    print()
