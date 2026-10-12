#!/usr/bin/env python3
"""
Index Landsat 8/9 Collection 2 Level-2 (DE Africa archive) for South Africa.

Products (must already exist -- see desa-ows/products/ls{8,9}_{sr,st}.odc-product.yaml):
  ls8_sr, ls8_st, ls9_sr, ls9_st

Source: s3://deafrica-landsat (public, unsigned -- DE Africa's AWS mirror of
the USGS Landsat Collection 2 Level-2 archive). Indexed directly from S3 via
`s3-to-dc --no-sign-request --stac`, no local download.

Scope: South Africa, full archive (2013-2026). The WRS-2 path/row grid below
was derived empirically, not guessed -- queried DE Africa's STAC API
(https://explorer.digitalearth.africa/stac) for collection `ls8_sr` with
bbox=[16,-35,33,-22] (South Africa) over Jan-Mar 2024, and took the unique
(landsat:wrs_path, landsat:wrs_row) pairs returned (109 total). The grid is
static (WRS-2 doesn't change), so this list is reused across the whole
archive rather than re-querying per run.

Only L2SP scenes carry a thermal band (_ST_stac.json); L2SR scenes are
SR-only. The per-product globs below select on both the sensor (LC08/LC09)
and the stac doc suffix (_SR_/_ST_), so ST indexing naturally only picks up
L2SP scenes -- no separate handling needed.

Usage:
  AWS_DEFAULT_REGION=af-south-1 python3 index_landsat_8_9.py
"""

import subprocess
import sys

BUCKET = "deafrica-landsat"
BASE = "collection02/level-2/standard/oli-tirs"

# path -> (row_min, row_max), South Africa coverage as of 2024-Q1 (see docstring)
PATH_ROWS = {
    167: (76, 81),
    168: (75, 83),
    169: (75, 83),
    170: (75, 84),
    171: (75, 84),
    172: (75, 84),
    173: (75, 84),
    174: (75, 84),
    175: (75, 84),
    176: (75, 83),
    177: (75, 81),
    178: (75, 80),
    179: (75, 77),
}

# (sensor prefix, stac suffix) per product
PRODUCTS = {
    "ls8_sr": ("LC08", "SR"),
    "ls8_st": ("LC08", "ST"),
    "ls9_sr": ("LC09", "SR"),
    "ls9_st": ("LC09", "ST"),
}


def pathrow_pairs():
    for path, (row_min, row_max) in sorted(PATH_ROWS.items()):
        for row in range(row_min, row_max + 1):
            yield f"{path:03d}", f"{row:03d}"


def main():
    pairs = list(pathrow_pairs())
    print(f"South Africa WRS-2 grid: {len(pairs)} path/row pairs")

    totals = {name: {"added": 0, "skipped": 0, "failed": 0} for name in PRODUCTS}

    for product, (sensor, suffix) in PRODUCTS.items():
        print(f"\n=== {product} ({sensor} {suffix}) ===")
        for path, row in pairs:
            uri = (
                f"s3://{BUCKET}/{BASE}/*/{path}/{row}/{sensor}_*/"
                f"*_{suffix}_stac.json"
            )
            result = subprocess.run(
                [
                    "s3-to-dc",
                    "--no-sign-request",
                    "--stac",
                    uri,
                    product,
                ],
                capture_output=True,
                text=True,
            )
            line = result.stdout.strip().splitlines()[-1] if result.stdout.strip() else ""
            if "Added" in line:
                added = int(line.split("Added ")[1].split(" ")[0])
                skipped = int(line.split("skipped ")[1].split(" ")[0])
                failed = int(line.split("failed ")[1].split(" ")[0])
                totals[product]["added"] += added
                totals[product]["skipped"] += skipped
                totals[product]["failed"] += failed
                if added or failed:
                    print(f"  {path}/{row}: {line}")
            else:
                print(f"  {path}/{row}: UNEXPECTED OUTPUT: {result.stdout!r} {result.stderr!r}")

        t = totals[product]
        print(f"  -- {product} totals: added={t['added']} skipped={t['skipped']} failed={t['failed']}")

    print("\n=== Summary ===")
    for product, t in totals.items():
        print(f"  {product}: added={t['added']} skipped={t['skipped']} failed={t['failed']}")


if __name__ == "__main__":
    main()
