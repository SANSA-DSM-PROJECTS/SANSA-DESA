import os
import pwd
import subprocess
import shutil
from oauthenticator.generic import GenericOAuthenticator

c = get_config()

# -----------------------
# Core Hub settings
# -----------------------
c.JupyterHub.bind_url = "http://127.0.0.1:8000/compute"
c.JupyterHub.base_url = "/compute"
c.JupyterHub.log_level = "DEBUG"

# -----------------------
# Proxy
# -----------------------
c.ConfigurableHTTPProxy.debug = True

# -----------------------
# Auth: Keycloak
# -----------------------
c.JupyterHub.authenticator_class = GenericOAuthenticator

c.GenericOAuthenticator.client_id = "jupyterhub"
c.GenericOAuthenticator.client_secret = "eyJhbGciOiJIUzUxMiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJkMjQ3YzVlZi02ZmY0LTQ1NzAtYWQ5MS04ZGM0YTc2ZTU4YWEifQ.eyJleHAiOjE3NzE1ODkyMjEsImlhdCI6MTc3MDcyNTIyMSwianRpIjoiYjI1MzcxYTItMmMyYS00ZmY5LTk4ZjQtYTczOTcwZTFiMzVhIiwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDo4MDgwL3JlYWxtcy9qdXB5dGVyLWh1YiIsImF1ZCI6Imh0dHA6Ly9sb2NhbGhvc3Q6ODA4MC9yZWFsbXMvanVweXRlci1odWIiLCJ0eXAiOiJJbml0aWFsQWNjZXNzVG9rZW4ifQ.GmjZc00HCmTVO6kzaTTpu1MJckMpz3fbTmpXW_U6-Pu8CpmMfnnkRKdKINKikSK90fK3YknFUsUokTRHVf3vAg"

c.GenericOAuthenticator.authorize_url = (
    "http://localhost:8080/realms/jupyter-hub/protocol/openid-connect/auth"
)
c.GenericOAuthenticator.token_url = (
    "http://localhost:8080/realms/jupyter-hub/protocol/openid-connect/token"
)
c.GenericOAuthenticator.userdata_url = (
    "http://localhost:8080/realms/jupyter-hub/protocol/openid-connect/userinfo"
)

c.GenericOAuthenticator.oauth_callback_url = (
    "http://localhost:8000/compute/hub/oauth_callback"
)

c.GenericOAuthenticator.username_key = "preferred_username"

c.Authenticator.allow_all = True
c.Authenticator.admin_users = {"admin"}


# -----------------------
# Spawner
# -----------------------
def pre_spawn_hook(spawner):
    username = spawner.user.name
    user_home = f"/home/{username}"
    notebooks_source = "/srv/jupyter/notebooks"
    notebooks_target = f"{user_home}/notebooks"

    try:
        pwd.getpwnam(username)
    except KeyError:
        subprocess.check_call(["useradd", "-ms", "/bin/bash", username])
        info = pwd.getpwnam(username)
        os.chown(user_home, info.pw_uid, info.pw_gid)

        if os.path.exists(notebooks_source):
            shutil.copytree(notebooks_source, notebooks_target, dirs_exist_ok=True)
            subprocess.check_call(
                ["chown", "-R", f"{username}:{username}", notebooks_target]
            )


c.Spawner.pre_spawn_hook = pre_spawn_hook
c.Spawner.default_url = "/lab"
