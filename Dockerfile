# Multi-stage Dockerfile for qBittorrent

# ==============================================================================
# Stage 1: Build Environment
# ==============================================================================
FROM ubuntu:26.04 AS builder

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install core build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    ccache \
    zip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install system dependencies
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install modern Qt6 libraries (Ubuntu 26.04 natively satisfies Qt >= 6.6.0)
RUN apt-get update && apt-get install -y \
    qt6-base-dev \
    qt6-base-private-dev \
    libqt6sql6-sqlite \
    qt6-tools-dev \
    qt6-l10n-tools \
    && rm -rf /var/lib/apt/lists/*

# Install qBittorrent core library dependencies
RUN apt-get update && apt-get install -y \
    libtorrent-rasterbar-dev \
    libboost-dev \
    libboost-system-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory for build artifacts
WORKDIR /build

# Copy source code into the container
COPY . /build/

# Configure the build with WebUI enabled and GUI disabled (headless mode)
RUN cmake -G "Ninja" -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DGUI=OFF \
    -DWEBUI=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache

# Compile the application using all available CPU threads
RUN cmake --build build -j$(nproc)

# MANUALLY MOVE BINARY: Avoids failing on missing man pages / documentation
RUN cp build/qbittorrent-nox /usr/local/bin/qbittorrent-nox


# ==============================================================================
# Stage 2: Final Lean Runtime Environment
# ==============================================================================
FROM ubuntu:26.04

# Prevent interactive prompts during runtime package setup
ENV DEBIAN_FRONTEND=noninteractive

# Install shared libraries required to run qBittorrent-nox
RUN apt-get update && apt-get install -y \
    libboost-system-dev \
    libboost-chrono-dev \
    libboost-random-dev \
    libssl3 \
    zlib1g \
    python3 \
    libtorrent-rasterbar2.0 \
    zip \
    libqt6core6 \
    libqt6network6 \
    libqt6sql6 \
    libqt6sql6-sqlite \
    libqt6xml6 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root system user for security purposes
RUN useradd -m -u 1001 qbittorrent && \
    mkdir -p /home/qbittorrent/downloads && \
    chown -R qbittorrent:qbittorrent /home/qbittorrent

# Copy the successfully placed binary from the builder stage
COPY --from=builder /usr/local/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

# Set execution workspace
WORKDIR /home/qbittorrent

# Drop root privileges and switch to the unprivileged app user
USER qbittorrent

# Expose default WebUI network port
EXPOSE 8080

# Configure default runtime environment flags
ENV QBT_WEBUI_PORT=8080
ENV QBT_DOWNLOADS_PATH=/home/qbittorrent/downloads

# Spin up the headless torrent daemon pointing to the user profile directory
CMD ["qbittorrent-nox", "--profile=/home/qbittorrent"]