FROM quay.io/jupyterhub/jupyterhub:5.2

# Auth + spawner + Postgres driver
RUN pip install --no-cache-dir \
      dockerspawner==13.0.0 \
      jupyterhub-nativeauthenticator==1.3.0 \
      jupyterhub-idle-culler==1.4.0 \
      psycopg2-binary==2.9.9 \
      oauthenticator==17.2.0

COPY jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py
WORKDIR /srv/jupyterhub

EXPOSE 8000
CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
