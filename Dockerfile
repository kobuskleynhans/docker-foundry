# Use ARM64v8 Debian as the base image
FROM arm64v8/debian:bullseye AS base
LABEL maintainer="git@luxusburg.lu"

ARG DEBIAN_FRONTEND="noninteractive"
VOLUME ["/home/foundry/server_files", "/home/foundry/persistent_data"]

# Set environment variables
ENV USER=foundry
ENV HOME=/home/$USER
ENV TZ='Europe/Berlin'
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install dependencies and box64/box86
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    curl \
    sudo \
    git \
    build-essential \
    cmake \
    python3 \
    python3-pip \
    jq \
    xvfb \
    xauth \
    cron \
    tzdata \
    locales \
    ca-certificates \
    libgl1-mesa-glx \
    libpulse0 \
    libasound2 \
    libncurses5 \
    libstdc++6 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxi6 \
    libdbus-1-3 \
    libfontconfig1 \
    libfreetype6 \
    libpng16-16 \
    libjpeg62-turbo \
    libtiff5 \
    libopenal1 \
    libv4l-0 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    && rm -rf /var/lib/apt/lists/*

# Install box64 and box86
RUN git clone https://github.com/ptitSeb/box64.git /tmp/box64 && \
    cd /tmp/box64 && mkdir build && cd build && cmake .. -DRPI4ARM64=1 --no-warn-unused-cli -Wno-dev && make -j$(nproc) && make install && \
    cd / && rm -rf /tmp/box64
RUN git clone https://github.com/ptitSeb/box86.git /tmp/box86 && \
    cd /tmp/box86 && mkdir build && cd build && cmake .. --no-warn-unused-cli -Wno-dev && make -j$(nproc) && make install && \
    cd / && rm -rf /tmp/box86

# Add i386 architecture for Wine and SteamCMD
RUN dpkg --add-architecture i386 && apt-get update && \
    apt-get install -y --no-install-recommends wine64 wine32 && \
    rm -rf /var/lib/apt/lists/*

# Download and install SteamCMD (x86_64)
RUN mkdir -p /opt/steamcmd && \
    cd /opt/steamcmd && \
    wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz && \
    tar -xzf steamcmd_linux.tar.gz && \
    rm steamcmd_linux.tar.gz

# Add new user
RUN groupadd -g ${PGUID:-1000} $USER && \
    useradd -d $HOME -u ${PUID:-1000} -g $USER $USER && \
    mkdir -p $HOME && \
    chown $USER:$USER $HOME

RUN echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER && \
    chmod 0440 /etc/sudoers.d/$USER

USER $USER
WORKDIR $HOME

# Copy batch files and give execute rights
ADD --chown=$USER:$USER ./files $HOME/scripts
RUN chmod +x $HOME/scripts/*.sh

# Set up environment for box64/box86
ENV BOX64_PATH=/usr/local/bin/box64
ENV BOX86_PATH=/usr/local/bin/box86
ENV STEAMCMD_PATH=/opt/steamcmd/steamcmd.sh

ENTRYPOINT ["/bin/bash", "/home/foundry/scripts/entrypoint.sh"]
CMD ["/home/foundry/scripts/start.sh"]

FROM base AS image-cron
USER root
# Setting up cron file for backup
ADD --chown=$USER:$USER ./files/foundry-cron /etc/cron.d/foundry-cron
RUN chmod 0644 /etc/cron.d/foundry-cron && \
    crontab /etc/cron.d/foundry-cron && \
    service cron start
USER $USER