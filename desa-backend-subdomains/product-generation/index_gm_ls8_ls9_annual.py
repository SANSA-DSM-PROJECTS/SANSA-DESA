#!/usr/bin/env python3
"""
Index Digital Earth Africa's Annual GeoMedian (GeoMAD) composite for
Landsat 8/9 -- product `gm_ls8_ls9_annual` -- for South Africa.

Product (must already exist -- see
product-generation/gm_ls8_ls9_annual.odc-product.yaml):
  gm_ls8_ls9_annual

This is a pre-mosaicked, cloud-free, seamless annual composite (one image
per calendar year covering the whole country), unlike the raw ls8_sr /
ls8_st / ls9_sr / ls9_st scenes (per WRS-2 path/row, per ~16-day pass) --
indexing this product is what gives TerriaMap a full-country Landsat view
instead of a single north-south stripe.

Source: s3://deafrica-services (DE Africa's services bucket, public,
unsigned). Indexed directly from S3 via `s3-to-dc --no-sign-request
--stac`, no local download.

Tiling scheme: unlike raw Landsat (WRS-2 path/row) or Sentinel-2 (MGRS
tiles), GeoMAD composites are organised on DE Africa's own Africa Albers
Equal Area grid (EPSG:6933), with tile ids of the form x###y###. The grid
below was derived empirically, not guessed -- queried DE Africa's STAC API
(https://explorer.digitalearth.africa/stac) for collection
`gm_ls8_ls9_annual` with bbox=[16,-35,33,-22] (South Africa), and took the
unique `odc:region_code` (x,y) tile ids returned (274 total, all years).
The grid is static (it's a fixed equal-area grid), so this list is reused
across all years rather than re-querying per run.

Scope: South Africa, full archive (2021-present, one dataset per tile per
year -- a much smaller job than the raw-scene backfill).

Usage:
  AWS_DEFAULT_REGION=af-south-1 python3 index_gm_ls8_ls9_annual.py
"""

import subprocess
import sys
from datetime import date

BUCKET = "deafrica-services"
PRODUCT = "gm_ls8_ls9_annual"
VERSION = "1-0-0"

# First year the product is available, per DE Africa docs. Index through
# the current year (a dataset for the current year may not exist yet if
# it hasn't been generated upstream -- that's fine, s3-to-dc just finds
# nothing for that glob and reports 0 added).
FIRST_YEAR = 2021
LAST_YEAR = date.today().year

# x -> (y_min, y_max), South Africa coverage (see docstring). Derived from
# the union of all years queried -- a tile present in any year is kept, so
# this grid is a superset safe to reuse across the whole archive.
TILE_GRID = {
    197: (34, 48),
    198: (33, 48),
    199: (33, 48),
    200: (33, 48),
    201: (33, 48),
    202: (33, 48),
    203: (33, 48),
    204: (33, 48),
    205: (33, 48),
    206: (33, 48),
    207: (33, 48),
    208: (33, 48),
    209: (34, 48),
    210: (34, 48),
    211: (34, 48),
    212: (35, 48),
    213: (37, 48),
    214: (37, 48),
}


def tile_pairs():
    for x, (y_min, y_max) in sorted(TILE_GRID.items()):
        for y in range(y_min, y_max + 1):
            yield f"{x:03d}", f"{y:03d}"


def main():
    tiles = list(tile_pairs())
    years = list(range(FIRST_YEAR, LAST_YEAR + 1))
    print(
        f"South Africa GeoMAD tile grid: {len(tiles)} tiles x "
        f"{len(years)} years ({years[0]}-{years[-1]})"
    )

    totals = {"added": 0, "skipped": 0, "failed": 0}

    for year in years:
        print(f"\n=== {year} ===")
        for x, y in tiles:
            uri = (
                f"s3://{BUCKET}/{PRODUCT}/{VERSION}/x{x}/y{y}/"
                f"{year}--P1Y/{PRODUCT}_x{x}y{y}_{year}--P1Y.stac-item.json"
            )
            result = subprocess.run(
                [
                    "s3-to-dc",
                    "--no-sign-request",
                    "--stac",
                    uri,
                    PRODUCT,
                ],
                capture_output=True,
                text=True,
            )
            line = (
                result.stdout.strip().splitlines()[-1]
                if result.stdout.strip()
                else ""
            )
            if "Added" in line:
                added = int(line.split("Added ")[1].split(" ")[0])
                skipped = int(line.split("skipped ")[1].split(" ")[0])
                failed = int(line.split("failed ")[1].split(" ")[0])
                totals["added"] += added
                totals["skipped"] += skipped
                totals["failed"] += failed
                if added or failed:
                    print(f"  x{x}y{y}/{year}: {line}")
            else:
                # Most commonly: no dataset exists for this tile/year
                # (tile outside this year's extent, or year not yet
                # generated upstream). Not a failure worth counting --
                # s3-to-dc just found no matching key.
                stderr = result.stderr.strip()
                if stderr and "NoSuchKey" not in stderr and "404" not in stderr:
                    print(f"  x{x}y{y}/{year}: UNEXPECTED OUTPUT: {result.stdout!r} {stderr!r}")

    print("\n=== Summary ===")
    print(
        f"  {PRODUCT}: added={totals['added']} "
        f"skipped={totals['skipped']} failed={totals['failed']}"
    )

    if totals["failed"]:
        sys.exit(1)


if __name__ == "__main__":
    main()
