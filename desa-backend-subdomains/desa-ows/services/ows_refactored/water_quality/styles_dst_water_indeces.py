# Styles for the dst_water_indeces product (DESA Water Quality Indices).
#
# Color ramps below are a first pass using standard remote-sensing
# conventions for each index type. Ranges are best-guess based on typical
# published values for each index; refine with the DST water quality
# program once real value distributions are known.

# color ramps-------------------------------------

awei_cr = [
    {"value": -1.0, "color": "#8F3F20", "alpha": 0.0},
    {"value": 0.0, "color": "#8F3F20", "alpha": 0.0},
    {"value": 0.05, "color": "#d8e7f5"},
    {"value": 0.2, "color": "#b0d2e8"},
    {"value": 0.4, "color": "#73b3d8"},
    {"value": 0.6, "color": "#3e8ec4"},
    {"value": 0.8, "color": "#1563aa"},
    {"value": 1.0, "color": "#08306b"},
]

ndci_cr = [
    {"value": -1.0, "color": "#2166ac", "alpha": 0.0},
    {"value": -0.2, "color": "#2166ac"},
    {"value": 0.0, "color": "#67a9cf"},
    {"value": 0.1, "color": "#d9f0d3"},
    {"value": 0.2, "color": "#a6d96a"},
    {"value": 0.4, "color": "#ffffbf"},
    {"value": 0.6, "color": "#fdae61"},
    {"value": 1.0, "color": "#d73027"},
]

ndti_cr = [
    {"value": -1.0, "color": "#f7fbff", "alpha": 0.0},
    {"value": -0.2, "color": "#f7fbff"},
    {"value": 0.0, "color": "#dfc3a3"},
    {"value": 0.2, "color": "#c6a173"},
    {"value": 0.4, "color": "#a67d4f"},
    {"value": 0.6, "color": "#805c37"},
    {"value": 1.0, "color": "#5c3f24"},
]

tss_cr = [
    {"value": 0.0, "color": "#f7f0e3", "alpha": 0.0},
    {"value": 1.0, "color": "#f7f0e3"},
    {"value": 10.0, "color": "#e3c99b"},
    {"value": 25.0, "color": "#c99d5f"},
    {"value": 50.0, "color": "#a3743a"},
    {"value": 75.0, "color": "#7a5127"},
    {"value": 100.0, "color": "#4d3016"},
]

fai_cr = [
    {"value": -0.1, "color": "#3288bd", "alpha": 0.0},
    {"value": -0.02, "color": "#3288bd"},
    {"value": 0.0, "color": "#e6f598"},
    {"value": 0.02, "color": "#abdda4"},
    {"value": 0.05, "color": "#66c2a5"},
    {"value": 0.1, "color": "#1b7837"},
]

abi_cr = [
    {"value": -1.0, "color": "#1a9850", "alpha": 0.0},
    {"value": -0.2, "color": "#1a9850"},
    {"value": 0.0, "color": "#d9ef8b"},
    {"value": 0.2, "color": "#fee08b"},
    {"value": 0.5, "color": "#fc8d59"},
    {"value": 1.0, "color": "#d73027"},
]

tds_cr = [
    {"value": 0.0, "color": "#f7fbff", "alpha": 0.0},
    {"value": 50.0, "color": "#f7fbff"},
    {"value": 150.0, "color": "#c6dbef"},
    {"value": 300.0, "color": "#6baed6"},
    {"value": 500.0, "color": "#2171b5"},
    {"value": 750.0, "color": "#08519c"},
    {"value": 1000.0, "color": "#08306b"},
]

# individual styles-------------------------------------

style_awei = {
    "name": "awei",
    "title": "AWEI - Automated Water Extraction Index",
    "abstract": "Automated Water Extraction Index - identifies open water, positive values indicate the presence of water",
    "index_function": {
        "function": "datacube_ows.band_utils.single_band",
        "mapped_bands": True,
        "kwargs": {"band": "awei"},
    },
    "needed_bands": ["awei"],
    "color_ramp": awei_cr,
    "range": [-1.0, 1.0],
    "legend": {
        "begin": "-1.0",
        "end": "1.0",
        "ticks_every": "0.2",
        "units": "unitless",
    },
}

style_ndci = {
    "name": "ndci",
    "title": "NDCI - Normalised Difference Chlorophyll Index",
    "abstract": "Normalised Difference Chlorophyll Index - a derived index that correlates with chlorophyll-a concentration and algal bloom risk",
    "index_function": {
        "function": "datacube_ows.band_utils.single_band",
        "mapped_bands": True,
        "kwargs": {"band": "ndci"},
    },
    "needed_bands": ["ndci"],
    "color_ramp": ndci_cr,
    "range": [-1.0, 1.0],
    "legend": {
        "begin": "-1.0",
        "end": "1.0",
        "ticks_every": "0.2",
        "units": "unitless",
    },
}

style_ndti = {
    "name": "ndti",
    "title": "NDTI - Normalised Difference Turbidity Index",
    "abstract": "Normalised Difference Turbidity Index - a derived index that correlates with water turbidity",
    "index_function": {
        "function": "datacube_ows.band_utils.single_band",
        "mapped_bands": True,
        "kwargs": {"band": "ndti"},
    },
    "needed_bands": ["ndti"],
    "color_ramp": ndti_cr,
    "range": [-1.0, 1.0],
    "legend": {
        "begin": "-1.0",
        "end": "1.0",
        "ticks_every": "0.2",
        "units": "unitless",
    },
}

style_tss = {
    "name": "tss",
    "title": "TSS - Total Suspended Solids",
    "abstract": "Total Suspended Solids concentration, in grams per cubic metre",
    "index_function": {
        "function": "datacube_ows.band_utils.single_band",
        "mapped_bands": True,
        "kwargs": {"band": "tss"},
    },
    "needed_bands": ["tss"],
    "color_ramp": tss_cr,
    "range": [0.0, 100.0],
    "legend": {
        "begin": "0",
        "end": "100",
        "ticks_every": "25",
        "units": "g/m3",
    },
}

style_fai = {
    "name": "fai",
    "title": "FAI - Floating Algae Index",
    "abstract": "Floating Algae Index - detects floating algae and vegetation on the water surface",
    "index_function": {
        "function": "datacube_ows.band_utils.single_band",
        "mapped_bands": True,
        "kwargs": {"band": "fai"},
    },
    "needed_bands": ["fai"],
    "color_ramp": fai_cr,
    "range": [-0.1, 0.1],
    "legend": {
        "begin": "-0.1",
        "end": "0.1",
        "ticks_every": "0.02",
        "units": "unitless",
    },
}

style_abi = {
    "name": "abi",
    "title": "ABI - Algal Bloom Index",
    "abstract": "Algal Bloom Index - indicates the severity of algal bloom conditions",
    "index_function": {
        "function": "datacube_ows.band_utils.single_band",
        "mapped_bands": True,
        "kwargs": {"band": "abi"},
    },
    "needed_bands": ["abi"],
    "color_ramp": abi_cr,
    "range": [-1.0, 1.0],
    "legend": {
        "begin": "-1.0",
        "end": "1.0",
        "ticks_every": "0.2",
        "units": "unitless",
    },
}

style_tds = {
    "name": "tds",
    "title": "TDS - Total Dissolved Solids",
    "abstract": "Total Dissolved Solids concentration, in milligrams per litre",
    "index_function": {
        "function": "datacube_ows.band_utils.single_band",
        "mapped_bands": True,
        "kwargs": {"band": "tds"},
    },
    "needed_bands": ["tds"],
    "color_ramp": tds_cr,
    "range": [0.0, 1000.0],
    "legend": {
        "begin": "0",
        "end": "1000",
        "ticks_every": "250",
        "units": "mg/L",
    },
}
