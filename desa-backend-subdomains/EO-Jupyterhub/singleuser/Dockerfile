# Single-user notebook image — Earth Observation stack.
#
# Based on the official Jupyter Docker Stacks scipy image, which already ships:
#   - the `jovyan` user, conda/mamba, and the SciPy stack (numpy/pandas/...)
#   - a `jupyterhub-singleuser` entrypoint, which DockerSpawner requires.
FROM quay.io/jupyter/scipy-notebook:2024-10-14

USER root
# System libs some geospatial wheels dlopen at runtime.
RUN apt-get update --yes \
    && apt-get install --yes --no-install-recommends \
       libgl1 \
       libspatialite8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

# ---------------------------------------------------------------------------
# Geospatial / Earth Observation core via conda-forge.
# Installing GDAL/PROJ/GEOS through conda avoids the C-library version hell you
# get mixing pip wheels — everything is built against one consistent stack.
# ---------------------------------------------------------------------------
RUN mamba install --yes -c conda-forge \
      'sqlite>=3.46' \
      'gdal' \
      'rasterio' \
      'rioxarray' \
      'xarray' \
      'dask' \
      'geopandas' \
      'shapely' \
      'fiona' \
      'pyproj' \
      'netcdf4' \
      'zarr' \
      'cartopy' \
      'contextily' \
      'folium' \
      'ipyleaflet' \
      'geoviews' \
      'datashader' \
      'stackstac' \
      'pystac-client' \
      'odc-stac' \
      'odc-geo' \
      'datacube' \
      'planetary-computer' \
      'scikit-image' \
      'scikit-learn' \
      'xarray-spatial' \
    && mamba clean --all --force-pkgs-dirs --yes

# Pure-Python EO helpers that are cleaner from pip.
RUN pip install --no-cache-dir \
      leafmap \
      sentinelhub \
      eodag \
      spyndex \
      odc-apps-dc-tools

# Rebuild the Jupyter font/config cache so the geo widgets load cleanly.
RUN fix-permissions "${CONDA_DIR}" && fix-permissions "/home/${NB_USER}"

WORKDIR /home/jovyan/work
