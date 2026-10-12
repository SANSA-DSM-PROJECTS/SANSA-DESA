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
# Geospatial / Earth Observation stack — its own conda env ("eo"), not the
# scipy-notebook base env.
#
# `mamba install`-ing GDAL/datacube/etc straight into the base env forces
# mamba to re-solve the base's ENTIRE existing (already large, pre-pinned)
# environment for compatibility, which can run for a very long time.
# `mamba create` solves a brand-new env with no prior constraints, which is
# dramatically faster. The tradeoff: notebooks must select the "Python (EO)"
# kernel to get this stack -- the base/default kernel does not have it.
# ---------------------------------------------------------------------------
RUN mamba create --yes -n eo -c conda-forge \
      python=3.11 \
      ipykernel \
      'sqlite>=3.46' \
      gdal \
      rasterio \
      rioxarray \
      xarray \
      dask \
      geopandas \
      shapely \
      fiona \
      pyproj \
      netcdf4 \
      zarr \
      odc-stac \
      odc-geo \
      datacube \
      psycopg2 \
      cartopy \
      contextily \
      folium \
      ipyleaflet \
      geoviews \
      datashader \
      stackstac \
      pystac-client \
      planetary-computer \
      scikit-image \
      scikit-learn \
      xarray-spatial \
    && mamba clean --all --force-pkgs-dirs --yes

# Register "eo" as a selectable Jupyter kernel. The notebook server process
# itself keeps running from the base env's jupyterlab; this just makes the
# eo env's Python available as a kernel choice.
RUN "${CONDA_DIR}/envs/eo/bin/python" -m ipykernel install \
      --prefix "${CONDA_DIR}" \
      --name eo \
      --display-name "Python (EO / datacube)"

# Pure-Python EO helpers that are cleaner from pip, installed into the eo
# env so they sit on the same kernel's path as datacube. The odc-* packages
# below are the rest of the opendatacube/odc-tools family (not on
# conda-forge, unlike odc-stac/odc-geo above) -- without them `datacube`
# can connect to the index but notebooks lose the masking/geomedian helpers
# (odc-algo), plotting/display helpers (odc-ui) and dataset caching
# (odc-dscache) that DE Africa notebooks expect. deafrica-tools replaces
# the old image's vendored Scripts/deafrica_*.py files with the maintained
# pip package.
RUN "${CONDA_DIR}/envs/eo/bin/pip" install --no-cache-dir \
      leafmap \
      sentinelhub \
      eodag \
      spyndex \
      odc-apps-dc-tools \
      odc-algo \
      odc-ui \
      odc-dscache \
      odc-stats \
      odc-apps-cloud \
      odc-cloud \
      odc-io \
      odc-loader \
      owslib \
      deafrica-tools

# Default Jupyter *terminals* to the eo env too. Notebooks don't need this
# (kernel selection alone puts them in eo -- see ipykernel install above),
# but a terminal just gets an interactive bash shell with whatever .bashrc
# leaves active, which the base image's conda init block leaves on "base".
RUN echo "conda activate eo" >> "/home/${NB_USER}/.bashrc"

# Rebuild the Jupyter font/config cache so the geo widgets load cleanly.
RUN fix-permissions "${CONDA_DIR}" && fix-permissions "/home/${NB_USER}"

WORKDIR /home/jovyan/work
