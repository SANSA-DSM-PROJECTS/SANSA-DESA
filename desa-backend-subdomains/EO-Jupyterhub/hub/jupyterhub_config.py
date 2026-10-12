import os

c = get_config()  # noqa

# ---------------------------------------------------------------------------
# Hub networking
# ---------------------------------------------------------------------------
# The hub process listens on all interfaces inside its container. DockerSpawner
# launches user containers on the same docker network and they must be able to
# call back to the hub, so the hub advertises itself by its service name.
c.JupyterHub.bind_url = "http://0.0.0.0:8000"
c.JupyterHub.hub_ip = "0.0.0.0"
c.JupyterHub.hub_connect_ip = "hub"          # matches the compose service name

# ---------------------------------------------------------------------------
# State database (Postgres) — survives hub restarts / rebuilds
# ---------------------------------------------------------------------------
pg_user = os.environ["POSTGRES_USER"]
pg_pass = os.environ["POSTGRES_PASSWORD"]
pg_host = os.environ["POSTGRES_HOST"]
pg_db = os.environ["POSTGRES_DB"]
c.JupyterHub.db_url = f"postgresql://{pg_user}:{pg_pass}@{pg_host}:5432/{pg_db}"

# The only meaningful hub-local state (everything else is in Postgres) is the
# cookie secret. Persist it on the /data volume so users aren't logged out on
# every hub restart. /data is a plain volume that does NOT shadow the config.
c.JupyterHub.cookie_secret_file = "/data/jupyterhub_cookie_secret"

# ---------------------------------------------------------------------------
# Authenticator — NativeAuthenticator (self sign-up + admin approval)
# ---------------------------------------------------------------------------
c.JupyterHub.authenticator_class = "nativeauthenticator.NativeAuthenticator"

admins = {
    u.strip()
    for u in os.environ.get("JUPYTERHUB_ADMIN_USERS", "admin").split(",")
    if u.strip()
}
c.Authenticator.admin_users = admins

# JupyterHub 5.x runs a base "allow" gate AFTER authentication. NativeAuthenticator
# already does its own gating: authenticate() returns None until a user is approved
# (is_authorized), and admins are auto-approved. So the approval queue is enforced
# there — the base gate must be open, or even approved users get "User not allowed".
c.Authenticator.allow_all = True
c.NativeAuthenticator.open_signup = os.environ.get(
    "NATIVE_AUTH_OPEN_SIGNUP", "true"
).lower() == "true"
c.NativeAuthenticator.ask_email_on_signup = os.environ.get(
    "NATIVE_AUTH_ASK_EMAIL", "true"
).lower() == "true"
c.NativeAuthenticator.minimum_password_length = int(
    os.environ.get("NATIVE_AUTH_MIN_PASSWORD_LEN", "10")
)
# Rate-limit brute force but stay workshop-friendly: lock for 1 min after 5
# failed logins (not 10 min after 3, which blocks legitimate setup fumbling).
c.NativeAuthenticator.allowed_failed_logins = 5
c.NativeAuthenticator.seconds_before_next_try = 60

# ---------------------------------------------------------------------------
# Spawner — DockerSpawner (one container + one persistent volume per user)
# ---------------------------------------------------------------------------
c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"

c.DockerSpawner.image = os.environ["DOCKER_NOTEBOOK_IMAGE"]
c.DockerSpawner.network_name = os.environ["DOCKER_NETWORK_NAME"]
c.DockerSpawner.use_internal_ip = True
# Remove the container when the server stops; the named volume below is what
# actually persists a user's files, so throwing away the container is safe.
c.DockerSpawner.remove = True
c.DockerSpawner.debug = False

notebook_dir = os.environ.get("DOCKER_NOTEBOOK_DIR", "/home/jovyan/work")
c.DockerSpawner.notebook_dir = notebook_dir

# Open Data Cube: hand every user container a ready-made connection to the ODC
# index DB. `datacube` reads DATACUBE_DB_URL directly, so no ~/.datacube.conf is
# needed. AWS_NO_SIGN_REQUEST lets ODC/odc-stac read public S3 buckets anonymously.
_dc_host = os.environ.get("DATACUBE_DB_HOST")
if _dc_host:
    _dc_url = (
        f"postgresql://{os.environ['DATACUBE_DB_USER']}:"
        f"{os.environ['DATACUBE_DB_PASSWORD']}@{_dc_host}:5432/"
        f"{os.environ['DATACUBE_DB_NAME']}"
    )
    c.DockerSpawner.environment = {
        "DATACUBE_DB_URL": _dc_url,
        "AWS_NO_SIGN_REQUEST": "YES",
    }

# Persist each user's home under a named volume: jupyterhub-user-<username>.
c.DockerSpawner.volumes = {
    "jupyterhub-user-{username}": notebook_dir,
}

# Per-user resource caps — tune to your host.
c.Spawner.mem_limit = os.environ.get("SINGLEUSER_MEM_LIMIT", "4G")
c.Spawner.cpu_limit = float(os.environ.get("SINGLEUSER_CPU_LIMIT", "2"))

# Give slow (large EO/ML) images time to pull/start before the hub gives up.
c.Spawner.start_timeout = 300
c.Spawner.http_timeout = 120

# ---------------------------------------------------------------------------
# Culling idle servers keeps the host from filling up with dead kernels.
# ---------------------------------------------------------------------------
c.JupyterHub.services = [
    {
        "name": "idle-culler",
        "admin": True,
        "command": [
            "python3", "-m", "jupyterhub_idle_culler",
            "--timeout=3600",          # cull servers idle for 1 hour
        ],
    }
]
c.JupyterHub.load_roles = [
    {
        "name": "idle-culler",
        "services": ["idle-culler"],
        "scopes": [
            "list:users",
            "read:users:activity",
            "delete:servers",
        ],
    }
]
