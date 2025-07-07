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

# Install headers needed for Box86 and Box64
RUN apt-get update && apt-get install -y \
    linux-headers-generic \
    && rm -rf /var/lib/apt/lists/*

# Create symlinks for missing syscall numbers
RUN mkdir -p /usr/include/asm && \
    ln -s /usr/include/asm-generic/unistd.h /usr/include/asm/unistd.h && \
    ln -s /usr/include/asm-generic/unistd_32.h /usr/include/asm/unistd_32.h && \
    ln -s /usr/include/asm-generic/unistd_64.h /usr/include/asm/unistd_64.h

# Install box64
RUN git clone https://github.com/ptitSeb/box64.git /tmp/box64 && \
    cd /tmp/box64 && mkdir build && cd build && cmake .. -DRPI4ARM64=1 && make -j$(nproc) && make install && \
    cd / && rm -rf /tmp/box64

# Install box86 with patched syscall definitions
RUN git clone https://github.com/ptitSeb/box86.git /tmp/box86 && \
    cd /tmp/box86 && \
    # Create a special include directory with required syscall definitions
    mkdir -p /tmp/include/asm && \
    echo "#ifndef _ASM_X86_UNISTD_H" > /tmp/include/asm/unistd.h && \
    echo "#define _ASM_X86_UNISTD_H" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_pipe 42" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_dup2 63" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_symlink 83" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_readlink 85" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_stat 106" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_lstat 107" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_sigprocmask 126" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR__llseek 140" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_getdents 141" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR__newselect 142" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR__sysctl 149" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_ugetrlimit 191" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_getuid32 199" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_getgid32 200" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_geteuid32 201" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_getegid32 202" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_setresuid32 208" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_getresuid32 209" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_setresgid32 210" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_getresgid32 211" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_utimes 271" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_inotify_init 291" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_stat64 195" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_lstat64 196" >> /tmp/include/asm/unistd.h && \
    echo "#define __NR_fstat64 197" >> /tmp/include/asm/unistd.h && \
    echo "struct stat64 {" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned long long st_dev;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned long long st_ino;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned int st_mode;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned int st_nlink;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned int st_uid;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned int st_gid;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned long long st_rdev;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned long long st_size;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned long long st_blksize;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned long long st_blocks;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned long long st_atime;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned long long st_mtime;" >> /tmp/include/asm/unistd.h && \
    echo "    unsigned long long st_ctime;" >> /tmp/include/asm/unistd.h && \
    echo "};" >> /tmp/include/asm/unistd.h && \
    echo "#endif /* _ASM_X86_UNISTD_H */" >> /tmp/include/asm/unistd.h && \
    mkdir build && cd build && \
    CFLAGS="-I/tmp/include" cmake .. && \
    CFLAGS="-I/tmp/include" make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/box86 /tmp/include

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
