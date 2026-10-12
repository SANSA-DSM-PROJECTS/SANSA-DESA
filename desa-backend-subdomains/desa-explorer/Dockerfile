FROM opendatacube/explorer:latest

USER root

COPY overlays/templates/layout/base.html \
    /app/lib/python3.12/site-packages/cubedash/templates/layout/base.html

COPY overlays/static/overview.ts \
     /app/lib/python3.12/site-packages/cubedash/static/overview.ts

COPY overlays/static/overview.js \
     /app/lib/python3.12/site-packages/cubedash/static/overview.js

# CARTO deprecated anonymous access to the free basemap tiles Explorer ships
# with by default (cartodb-basemaps-*.fastly.net now returns a watermarked
# "API KEY REQUIRED" placeholder instead of map tiles) -- swapped for Esri's
# free no-key World_Street_Map service on the dataset detail and region map
# pages.
COPY overlays/templates/dataset.html \
     /app/lib/python3.12/site-packages/cubedash/templates/dataset.html

COPY overlays/templates/region.html \
     /app/lib/python3.12/site-packages/cubedash/templates/region.html
