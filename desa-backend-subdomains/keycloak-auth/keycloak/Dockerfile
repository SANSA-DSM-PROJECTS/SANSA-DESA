FROM quay.io/keycloak/keycloak:26.7.4

# Copy providers only if present
#COPY providers /opt/keycloak/providers/

# ---------------------------------------------------------------------------
# Build-time options. These MUST be set before `kc.sh build` so the server can
# later be started with `start --optimized` (which skips the ~30s build step at
# container start). Runtime env in the compose file still supplies the DB URL,
# credentials, hostname, etc. — only the *feature set* is fixed here.
# ---------------------------------------------------------------------------
ENV KC_DB=postgres
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Custom themes and the realm to import on first boot are baked into the image
# so the running container is the single source of truth (no bind-mounts in prod).
COPY themes /opt/keycloak/themes/
COPY realm-import /opt/keycloak/data/import/

RUN /opt/keycloak/bin/kc.sh build

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
