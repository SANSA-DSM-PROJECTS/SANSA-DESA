from ows_refactored.common.ows_reslim_cfg import reslim_wms_min_zoom_15
from ows_refactored.water_quality.band_dst_water_indeces_cfg import (
    bands_dst_water_indeces,
)
from ows_refactored.water_quality.styles_dst_water_indeces import (
    style_awei,
    style_ndci,
    style_ndti,
    style_tss,
    style_fai,
    style_abi,
    style_tds,
)

layer = {
    "title": "DESA Water Quality Indices",
    "name": "dst_water_indeces",
    "abstract": """
DESA Water Quality Indices provide monthly national mosaics of seven water quality indicators for South African surface water bodies, derived from Sentinel-2 imagery.

The product contains the following bands:
- awei ("AWEI"): Automated Water Extraction Index, used to delineate open water.
- ndci ("NDCI"): Normalised Difference Chlorophyll Index, an indicator of chlorophyll-a concentration and algal bloom risk.
- ndti ("NDTI"): Normalised Difference Turbidity Index, an indicator of water turbidity.
- tss ("TSS"): Total Suspended Solids, in grams per cubic metre.
- fai ("FAI"): Floating Algae Index, used to detect floating algae and vegetation.
- abi ("ABI"): Algal Bloom Index, an indicator of algal bloom severity.
- tds ("TDS"): Total Dissolved Solids, in milligrams per litre.

This service provides data monthly at a spatial resolution of 20 m.
""",
    "product_name": "dst_water_indeces",
    "time_resolution": "month",
    "bands": bands_dst_water_indeces,
    "resource_limits": reslim_wms_min_zoom_15,
    "image_processing": {
        "extent_mask_func": "datacube_ows.ogc_utils.mask_by_val",
        "always_fetch_bands": [],
        "manual_merge": False,
    },
    "native_crs": "EPSG:32735",
    "native_resolution": [20, -20],
    "styling": {
        "default_style": "awei",
        "styles": [
            style_awei,
            style_ndci,
            style_ndti,
            style_tss,
            style_fai,
            style_abi,
            style_tds,
        ],
    },
}
