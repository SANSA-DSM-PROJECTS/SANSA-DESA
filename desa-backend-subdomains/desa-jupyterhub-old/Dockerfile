# Use the GDAL base image
FROM ghcr.io/osgeo/gdal:ubuntu-full-3.10.0

ENV SHELL=bash \
    DEBIAN_FRONTEND=non-interactive \
    USE_PYGEOS=0 \
    SPATIALITE_LIBRARY_PATH='mod_spatialite.so'

RUN rm -f /etc/apt/sources.list.d/apache-arrow.sources
# Install dependencies and JupyterHub
RUN apt update --yes \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt install --yes --fix-missing --no-install-recommends \
    # developer convenience
    fish \
    git \
    graphviz \
    htop \
    iproute2 \
    iputils-ping \
    jq \
    less \
    libtiff-tools \
    net-tools \
    openssh-client \
    postgresql \
    postgresql-client \
    python3-dev \
    python3-full \
    rsync \
    simpleproxy \
    sudo \
    tig \
    tini \
    tmux \
    vim \
    xz-utils \
    zip \
    # build psycopg2
    libpq-dev \
    # for cython to work need compilers
    build-essential \
    # install ffmpeg the normal way
    ffmpeg \
    nodejs \
    # Spatialite support
    libsqlite3-mod-spatialite \
    # install texlive
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic

# Install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq

# install pandoc
RUN wget https://github.com/jgm/pandoc/releases/download/3.6/pandoc-3.6-1-amd64.deb \
    && apt --fix-broken install \
    && dpkg -i pandoc-3.6-1-amd64.deb \
    && rm pandoc-3.6-1-amd64.deb

ARG NB_USER="sansa-desa"
ARG NB_UID="1000"
ARG NB_GID="100" 

# Configure environment
ENV HOME="/home/${NB_USER}"
ENV VIRTUAL_ENV="/opt/venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

# Delete existing user with UID="${NB_UID}" if it exists
RUN if grep -q "${NB_UID}" /etc/passwd; then \
    userdel --remove $(id -un "${NB_UID}"); \
    fi
# Create a non-root user
RUN useradd --no-log-init --create-home --shell /bin/bash --no-user-group --gid $NB_GID --uid $NB_UID  $NB_USER \
    && chown -R $NB_UID:$NB_GID $HOME
# Set up the python virtual environment PEP 668
RUN python3 -m venv $VIRTUAL_ENV \
    && chown -R $NB_UID:$NB_GID  $VIRTUAL_ENV


COPY requirements.txt /
COPY datacube.conf /etc/

USER $NB_USER
RUN python -m pip install --upgrade pip pip-tools
RUN pip install --no-cache-dir -r requirements.txt
# Enable server extensions
RUN jupyter server extension enable --py --sys-prefix jupyterlab_iframe jupyter_resource_usage 
# Fix to ensure numpy-based raster support has been properly installed
RUN pip install --no-cache --force-reinstall gdal=="$(gdal-config --version).*"


USER root
# Install JupyterHub and required Python packages
RUN pip install --no-cache \
    notebook \
    oauthenticator \
    dockerspawner \
    jupyterhub \
    jupyterhub-nativeauthenticator

# activate datacube 
#RUN datacube system init

# Install the JupyterHub proxy
RUN npm install -g configurable-http-proxy

# Create a directory for template notebooks
RUN mkdir -p /srv/jupyter/notebooks

# Copy pre-written notebooks to the container
COPY notebooks/ /srv/jupyter/notebooks/

# Ensure correct permissions
RUN chmod -R 755 /srv/jupyter/notebooks

# Copy JupyterHub configuration file
COPY jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py

# Expose port 8000 for JupyterHub
EXPOSE 8000

# Set up command to run JupyterHub
CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]