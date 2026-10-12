ows_cfg = {
    "global": {
        # Master config for all services and products.
        "response_headers": {
            "Access-Control-Allow-Origin": "*",  # CORS header
        },
        "services": {
            "wms": True,
            "wcs": True,
            "wmts": True,
        },
        "published_CRSs": {
            "EPSG:3857": {  # Web Mercator
                "geographic": False,
                "horizontal_coord": "x",
                "vertical_coord": "y",
            },
            "EPSG:4326": {"geographic": True, "vertical_coord_first": True},  # WGS-84
            "EPSG:6933": {  # Cylindrical equal area
                "geographic": False,
                "horizontal_coord": "x",
                "vertical_coord": "y",
            },
            "EPSG:32735": {  # WGS 84 / UTM zone 35S
                "geographic": False,
                "horizontal_coord": "x",
                "vertical_coord": "y",
            },
        },
        "allowed_urls": [
            "https://desa-ows.sansa.org.za/",
            "https://desadev-ows.sansa.org.za/",
            "https://desa.sansa.org.za/ows/",
            "http://localhost:8000",
        ],
        # Metadata to go straight into GetCapabilities documents
        "title": "Digital Earth South Africa - OGC Web Services",
        "abstract": """Digital Earth South Africa OGC Web Services""",
        "info_url": "https://desadev.sansa.org.za/",
        "keywords": [
            "landsat",
            "south-africa",
            "spot-6",
            "spot-7",
            "time-series",
        ],
        "contact_info": {
            "person": "Digital Earth South Africa",
            "organisation": "South African National Space Agency",
            "position": "",
            "address": {
                "type": "postal",
                "address": "PO Box 484",
                "city": "Pretoria",
                "state": "Gauteng",
                "postcode": "0127",
                "country": "South Africa",
            },
            "telephone": "012 334-5000",
            "fax": "",
            "email": "ingqambuza@sansa.org.za",
        },
        "fees": "",
        "access_constraints": ""
        "This product is released under the Creative Commons Attribution 4.0 International Licence. "
        "http://creativecommons.org/licenses/by/4.0/legalcode",
        "translations_directory": "/env/config/ows_refactored/translations",
        "supported_languages": [
            "en",  # English  - the default language, the language used in the untranslated metadata.
            "fr",  # French
        ],
    },  # END OF global SECTION
    "wms": {
        # Config for WMS service, for all products/layers
        "s3_aws_zone": "af-south-1",
        "max_width": 512,
        "max_height": 512,
    },  # END OF wms SECTION
    "wcs": {
        # Config for WCS service, for all products/coverages
        "default_geographic_CRS": "EPSG:4326",
        "formats": {
            "GeoTIFF": {
                # "renderer": "datacube_ows.wcs_utils.get_tiff",
                "renderers": {
                    "1": "datacube_ows.wcs1_utils.get_tiff",
                    "2": "datacube_ows.wcs2_utils.get_tiff",
                },
                "mime": "image/geotiff",
                "extension": "tif",
                "multi-time": False,
            },
            "netCDF": {
                # "renderer": "datacube_ows.wcs_utils.get_netcdf",
                "renderers": {
                    "1": "datacube_ows.wcs1_utils.get_netcdf",
                    "2": "datacube_ows.wcs2_utils.get_netcdf",
                },
                "mime": "application/x-netcdf",
                "extension": "nc",
                "multi-time": True,
            },
        },
        "native_format": "GeoTIFF",
    },  # END OF wcs SECTION
    "layers": [
        {
            "title": "Digital Earth South Africa - OGC Web Services",
            "abstract": "Digital Earth South Africa OGC Web Services",
            "layers": [
                # Hierarchical list of layers.  May be a combination of unnamed/unmappable
                # folder-layers or named mappable layers.
                {
                    "title": "Satellite images",
                    "abstract": """Satellite images""",
                    "layers": [
                        {
                            "title": "Surface reflectance",
                            "abstract": """Surface reflectance""",
                            "layers": [
                                {
                                    "title": "Daily surface reflectance",
                                    "abstract": """Daily surface reflectance""",
                                    "layers": [
                                        {
                                            "include": "ows_refactored.surface_reflectance.ows_s2_cfg.layer",
                                            "type": "python",
                                        },
                                        {
                                            "include": "ows_refactored.surface_reflectance.ows_lsc2_sr_cfg.layer_ls9",
                                            "type": "python",
                                        },
                                        {
                                            "include": "ows_refactored.surface_reflectance.ows_lsc2_sr_cfg.layer_ls8",
                                            "type": "python",
                                        },
                                        {
                                            "include": "ows_refactored.surface_reflectance.ows_lsc2_sr_cfg.layer_ls7",
                                            "type": "python",
                                        },
                                        {
                                            "include": "ows_refactored.surface_reflectance.ows_lsc2_sr_cfg.layer_ls5",
                                            "type": "python",
                                        },
                                    ],
                                },
                                {
                                    "title": "Annual surface reflectance",
                                    "abstract": """Annual surface reflectance composites""",
                                    "layers": [
                                        {
                                            "include": "ows_refactored.surface_reflectance.ows_gm_ls8_ls9_annual_cfg.layer",
                                            "type": "python",
                                        },
                                    ],
                                },
                            ],
                        },
                        {
                            "title": "Surface temperature",
                            "abstract": """Surface temperature""",
                            "layers": [
                                {
                                    "title": "Daily surface temperature",
                                    "abstract": """Daily surface temperature""",
                                    "layers": [
                                        {
                                            "include": "ows_refactored.surface_temperature.ows_lsc2_st_cfg.layer_ls9",
                                            "type": "python",
                                        },
                                        {
                                            "include": "ows_refactored.surface_temperature.ows_lsc2_st_cfg.layer_ls8",
                                            "type": "python",
                                        },
                                        {
                                            "include": "ows_refactored.surface_temperature.ows_lsc2_st_cfg.layer_ls7",
                                            "type": "python",
                                        },
                                        {
                                            "include": "ows_refactored.surface_temperature.ows_lsc2_st_cfg.layer_ls5",
                                            "type": "python",
                                        },
                                    ],
                                },
                            ],
                        },
                    ],
                },
                {
                    "title": "Water Indices",
                    "abstract": """Water Indices""",
                    "layers": [
                        {
                            "include": "ows_refactored.water_quality.ows_dst_water_indeces_cfg.layer",
                            "type": "python",
                        },
                    ],
                },
            ],
        }
    ],
}
