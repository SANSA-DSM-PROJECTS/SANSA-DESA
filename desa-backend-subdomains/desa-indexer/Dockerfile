FROM python:3.12-slim

# System deps for psycopg2 (libpq-dev, gcc) and rasterio's dynamic linking
# (libexpat1 -- without it, `import rasterio` fails with
# "libexpat.so.1: cannot open shared object file").
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    libexpat1 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    datacube \
    odc-apps-dc-tools \
    psycopg2-binary

# No app code baked in -- indexing scripts are bind-mounted from
# ./product-generation at runtime (see docker-compose.yaml) so they can be
# edited/added without rebuilding this image. This container just sits idle;
# Ofelia (see docker-compose.yaml labels) runs scripts in it on a schedule
# via `docker exec`.
CMD ["sleep", "infinity"]
