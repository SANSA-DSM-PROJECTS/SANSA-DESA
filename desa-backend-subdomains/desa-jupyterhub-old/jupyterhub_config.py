import pwd, subprocess, os, nativeauthenticator, shutil

c = get_config()  # noqa


c.JupyterHub.disable_check_xsrf = True

c.JupyterHub.tornado_settings = {
    "headers": {
        "Content-Security-Policy": "frame-ancestors *",
        #"Content-Security-Policy": "frame-ancestors 'self' http://10.150.16.180/",
    }
}

c.JupyterHub.base_url = '/'


c.Authenticator.admin_users = {"admin", "indi", "user-admin"}

c.Authenticator.allow_all = True



# c.JupyterHub.authenticator_class = 'github'

c.JupyterHub.authenticator_class = "native"
c.JupyterHub.template_paths = [
    f"{os.path.dirname(nativeauthenticator.__file__)}/templates/"
]


def pre_spawn_hook(spawner):
    username = spawner.user.name
    user_home = f"/home/{username}"
    notebooks_source = "/srv/jupyter/notebooks"
    notebooks_target = f"{user_home}/notebooks"
    try:
        pwd.getpwnam(username)
    except KeyError:
        subprocess.check_call(["useradd", "-ms", "/bin/bash", username])
        user_info = pwd.getpwnam(username)  # Get user info for UID/GID
        user_uid = user_info.pw_uid
        user_gid = user_info.pw_gid
        os.chown(user_home, user_uid, user_gid)  # Set user-specific permissions

        if os.path.exists(notebooks_source):
            shutil.copytree(notebooks_source, notebooks_target, dirs_exist_ok=True)
            subprocess.check_call(["chown", "-R", f"{username}:{username}", notebooks_target])


c.Spawner.pre_spawn_hook = pre_spawn_hook

c.Spawner.default_url = "/lab"

#c.Spawner.notebook_dir = '/home'
