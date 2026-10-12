#!/usr/bin/env python3
"""
Index Sentinel-2 Level-2A surface reflectance (DE Africa archive) for South Africa.

Product (must already exist -- see product-generation/s2_l2a.odc-product.yaml,
a straight copy of DE Africa's own upstream definition
https://raw.githubusercontent.com/digitalearthafrica/config/master/products/esa_s2_l2a.odc-product.yaml,
chosen because its band aliases line up exactly with what
desa-ows/services/ows_refactored/surface_reflectance/band_sr_cfg.py
(bands_sentinel) expects for the s2_l2a OWS layer):
  s2_l2a

Source: s3://deafrica-sentinel-2 (public, unsigned -- DE Africa's COG mirror
of the ESA Sentinel-2 L2A archive, Sinergise/Element 84 processed). Indexed
directly from S3 via `s3-to-dc --no-sign-request --stac`, no local download.
The collection id `s2_l2a` was confirmed empirically against DE Africa's
STAC API (https://explorer.digitalearth.africa/stac/search?collections=s2_l2a),
which returned real South-Africa-adjacent items with the expected band set
(B01..B12, B8A, AOT, WVP, SCL).

WHY S3 GLOBS INSTEAD OF stac-to-dc AGAINST THE STAC API
--------------------------------------------------------
stac-to-dc can also query the STAC API directly (`--catalog-href ...
--collections s2_l2a --bbox ... --datetime ...`), which is what DE Africa's
own docs recommend and avoids needing a tile grid at all. In practice this
was tried first and measured too slow to use for a full-archive backfill:
the explorer API takes ~15-18s per 100-item search page regardless of load,
and a bbox+datetime count query for the full South Africa archive returned
numberMatched=459068 -- at the observed ~20-40 datasets/minute via the STAC
API that is on the order of a week of continuous indexing. Switching to
`s3-to-dc` globs straight against S3 (bypassing the explorer API entirely)
measured ~800-1000 datasets/minute instead, because it's just an S3 prefix
listing + reading each STAC json directly from S3, no slow API in the loop.

Each Sentinel-2 L2A scene on S3 lives at:
  s3://deafrica-sentinel-2/sentinel-s2-l2a-cogs/<utm_zone>/<lat_band>/<grid_square>/<year>/<month>/S2{A,B}_<tile>_<date>_<seq>_L2A/S2{A,B}_<tile>_<date>_<seq>_L2A.json
e.g. .../35/H/KB/2024/1/S2A_35HKB_20240109_0_L2A/S2A_35HKB_20240109_0_L2A.json
confirmed by listing the bucket directly (`aws s3 ls --no-sign-request`).

IMPORTANT GLOB QUIRK (found empirically, not documented upstream): odc's
s3-to-dc glob matching fails silently ("Doc stream was empty") whenever a
path segment mixes a literal prefix with a trailing `*`, e.g.
`S2*_L2A.json` or `S2A_<tile>_*_L2A.json` -- both matched zero objects even
though the exact literal path indexed fine and `aws s3 ls` showed matching
keys. Patterns where the wildcard comes FIRST in the segment (`*_L2A.json`,
`*.json`) work correctly and were verified to add real datasets. So every
glob below ends in `*_L2A.json`, never `S2*_L2A.json`.

Scope: South Africa, full available archive. DE Africa's Sentinel-2 L2A
coverage for the South Africa bbox [16,-35,33,-22] starts 2017-01-01
(verified by sorting the STAC API ascending by datetime) and is updated
continuously through the present.

THE TILE GRID
-------------
Sentinel-2 uses the MGRS 100km-tile grid, not Landsat's simple WRS-2
path/row grid, so unlike index_landsat_8_9.py this can't be a small
hand-rolled table of path/row ranges. The grid below (335 tiles) was
derived computationally, not guessed: every 0.25-degree point in the South
Africa bounding box [16,-35,33,-22] (same bbox used for Landsat) was
converted to its MGRS 100km tile id with the `mgrs` python library
(`mgrs.MGRS().toMGRS(lat, lon, MGRSPrecision=0)`), and the unique
(utm_zone, lat_band, grid_square) triples were collected. This is a static
grid (MGRS doesn't change), so it's reused across the whole archive rather
than recomputed per run -- same approach as Landsat's static WRS-2 table.
Many of these 335 tiles are mostly ocean or just clip a corner of the bbox
rectangle and will have little or no data; s3-to-dc handles that fine
(reports "Doc stream was empty" and moves on), it just costs a few seconds
per empty tile.

Indexing loops per tile (not per month/year) because each tile's glob
already spans every year/month available for that tile in a single
s3-to-dc call -- far fewer subprocess invocations than looping dates too,
and verified to run in roughly 1-3 minutes per tile with data.

Usage:
  AWS_DEFAULT_REGION=af-south-1 python3 index_s2_l2a.py
"""

import subprocess

BUCKET = "deafrica-sentinel-2"
BASE = "sentinel-s2-l2a-cogs"
PRODUCT = "s2_l2a"

# South Africa MGRS 100km tile grid (utm_zone + lat_band + grid_square), derived
# from bbox [16,-35,33,-22] -- see docstring above for how this was generated.
TILES = [
    "33HWB", "33HWC", "33HWD", "33HWE", "33HXB", "33HXC", "33HXD", "33HXE",
    "33HYB", "33HYC", "33HYD", "33HYE", "33JWE", "33JWF", "33JWG", "33JWH",
    "33JWJ", "33JWK", "33JWL", "33JXE", "33JXF", "33JXG", "33JXH", "33JXJ",
    "33JXK", "33JXL", "33JXM", "33JXN", "33JXP", "33JYE", "33JYF", "33JYG",
    "33JYH", "33JYJ", "33JYK", "33JYL", "33JYM", "33JYN", "33JYP", "33KXP",
    "33KXQ", "33KXR", "33KYP", "33KYQ", "33KYR", "34HBG", "34HBH", "34HBJ",
    "34HBK", "34HCG", "34HCH", "34HCJ", "34HCK", "34HDG", "34HDH", "34HDJ",
    "34HDK", "34HEG", "34HEH", "34HEJ", "34HEK", "34HFG", "34HFH", "34HFJ",
    "34HFK", "34HGG", "34HGH", "34HGJ", "34HGK", "34JAS", "34JAT", "34JAU",
    "34JBK", "34JBL", "34JBM", "34JBN", "34JBP", "34JBQ", "34JBR", "34JBS",
    "34JBT", "34JBU", "34JCK", "34JCL", "34JCM", "34JCN", "34JCP", "34JCQ",
    "34JCR", "34JCS", "34JCT", "34JCU", "34JDK", "34JDL", "34JDM", "34JDN",
    "34JDP", "34JDQ", "34JDR", "34JDS", "34JDT", "34JDU", "34JEK", "34JEL",
    "34JEM", "34JEN", "34JEP", "34JEQ", "34JER", "34JES", "34JET", "34JEU",
    "34JFK", "34JFL", "34JFM", "34JFN", "34JFP", "34JFQ", "34JFR", "34JFS",
    "34JFT", "34JFU", "34JGK", "34JGL", "34JGM", "34JGN", "34JGP", "34JGQ",
    "34JGR", "34JGS", "34JGT", "34JGU", "34KAA", "34KAU", "34KAV", "34KBA",
    "34KBU", "34KBV", "34KCA", "34KCU", "34KCV", "34KDA", "34KDU", "34KDV",
    "34KEA", "34KEU", "34KEV", "34KFA", "34KFU", "34KFV", "34KGA", "34KGU",
    "34KGV", "35HKB", "35HKC", "35HKD", "35HKE", "35HLB", "35HLC", "35HLD",
    "35HLE", "35HMB", "35HMC", "35HMD", "35HME", "35HNB", "35HNC", "35HND",
    "35HNE", "35HPB", "35HPC", "35HPD", "35HPE", "35HQB", "35HQC", "35HQD",
    "35HQE", "35JJM", "35JJN", "35JJP", "35JKE", "35JKF", "35JKG", "35JKH",
    "35JKJ", "35JKK", "35JKL", "35JKM", "35JKN", "35JKP", "35JLE", "35JLF",
    "35JLG", "35JLH", "35JLJ", "35JLK", "35JLL", "35JLM", "35JLN", "35JLP",
    "35JME", "35JMF", "35JMG", "35JMH", "35JMJ", "35JMK", "35JML", "35JMM",
    "35JMN", "35JMP", "35JNE", "35JNF", "35JNG", "35JNH", "35JNJ", "35JNK",
    "35JNL", "35JNM", "35JNN", "35JNP", "35JPE", "35JPF", "35JPG", "35JPH",
    "35JPJ", "35JPK", "35JPL", "35JPM", "35JPN", "35JPP", "35JQE", "35JQF",
    "35JQG", "35JQH", "35JQJ", "35JQK", "35JQL", "35JQM", "35JQN", "35JQP",
    "35KJP", "35KJQ", "35KJR", "35KKP", "35KKQ", "35KKR", "35KLP", "35KLQ",
    "35KLR", "35KMP", "35KMQ", "35KMR", "35KNP", "35KNQ", "35KNR", "35KPP",
    "35KPQ", "35KPR", "35KQP", "35KQQ", "35KQR", "36HTG", "36HTH", "36HTJ",
    "36HTK", "36HUG", "36HUH", "36HUJ", "36HUK", "36HVG", "36HVH", "36HVJ",
    "36HVK", "36HWG", "36HWH", "36HWJ", "36HWK", "36JSS", "36JST", "36JSU",
    "36JTK", "36JTL", "36JTM", "36JTN", "36JTP", "36JTQ", "36JTR", "36JTS",
    "36JTT", "36JTU", "36JUK", "36JUL", "36JUM", "36JUN", "36JUP", "36JUQ",
    "36JUR", "36JUS", "36JUT", "36JUU", "36JVK", "36JVL", "36JVM", "36JVN",
    "36JVP", "36JVQ", "36JVR", "36JVS", "36JVT", "36JVU", "36JWK", "36JWL",
    "36JWM", "36JWN", "36JWP", "36JWQ", "36JWR", "36JWS", "36JWT", "36JWU",
    "36KSA", "36KSU", "36KSV", "36KTA", "36KTU", "36KTV", "36KUA", "36KUU",
    "36KUV", "36KVA", "36KVU", "36KVV", "36KWA", "36KWU", "36KWV",
]


def tile_parts(tile):
    # "35HKB" -> zone="35", band="H", square="KB"
    return tile[:2], tile[2], tile[3:]


def main():
    print(f"South Africa MGRS tile grid: {len(TILES)} tiles")

    totals = {"added": 0, "skipped": 0, "failed": 0}

    for tile in TILES:
        zone, band, square = tile_parts(tile)
        uri = (
            f"s3://{BUCKET}/{BASE}/{zone}/{band}/{square}/*/*/*/*_L2A.json"
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

        output = result.stdout.strip()
        stderr = result.stderr.strip()
        line = ""
        for candidate in output.splitlines()[::-1]:
            if "Added" in candidate and "dataset" in candidate:
                line = candidate
                break

        if line:
            try:
                added = int(line.split("Added ")[1].split(" ")[0])
                skipped = int(line.split("skipped ")[1].split(" ")[0])
                failed = int(line.split("failed ")[1].split(" ")[0])
            except (IndexError, ValueError):
                print(f"  {tile}: UNEXPECTED OUTPUT: {output!r} {stderr!r}")
                continue
            totals["added"] += added
            totals["skipped"] += skipped
            totals["failed"] += failed
            if added or failed:
                print(f"  {tile}: added={added} skipped={skipped} failed={failed}")
        elif "Doc stream was empty" in output or "Doc stream was empty" in stderr:
            pass  # tile has no data (e.g. ocean / outside actual coverage) -- expected
        else:
            print(f"  {tile}: UNEXPECTED OUTPUT: {output!r} {stderr!r}")

    print("\n=== Summary ===")
    print(
        f"  {PRODUCT}: added={totals['added']} "
        f"skipped={totals['skipped']} failed={totals['failed']}"
    )


if __name__ == "__main__":
    main()
