# Multi-stage Dockerfile for qBittorrent
# Stage 1: Build
FROM ubuntu:26.04 AS builder

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    libboost-dev \
    libboost-system-dev \
    libboost-chrono-dev \
    libboost-random-dev \
    libboost-python-dev \
    libssl-dev \
    zlib1g-dev \
    python3-dev \
    libqt6-dev \
    libqt6websockets-dev \
    qt6-base-dev \
    qt6-tools-dev \
    qt6-svg-dev \
    && rm -rf /var/lib/apt/lists/*

# Install libtorrent-rasterbar
RUN apt-get update && apt-get install -y \
    libtorrent-rasterbar-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy source code
COPY . /build/

# Configure and build qBittorrent with WebUI enabled (no GUI for Docker)
RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DGUI=OFF \
    -DWEBUI=ON \
    -DCMAKE_INSTALL_PREFIX=/usr

RUN cmake --build build -j$(nproc)

# Stage 2: Runtime
FROM ubuntu:26.04

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libboost-system \
    libboost-chrono \
    libboost-random \
    libssl3 \
    zlib1g \
    python3 \
    libtorrent-rasterbar \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 qbittorrent && \
    mkdir -p /home/qbittorrent/downloads && \
    chown -R qbittorrent:qbittorrent /home/qbittorrent

# Copy built binary from builder stage
COPY --from=builder /build/build/qbittorrent-nox /usr/bin/qbittorrent-nox

# Copy WebUI files
COPY --from=builder /build/src/webui/www /usr/share/qbittorrent/www

# Set working directory
WORKDIR /home/qbittorrent

# Switch to non-root user
USER qbittorrent

# Expose WebUI port
EXPOSE 8080

# Set environment variables
ENV QBT_WEBUI_PORT=8080
ENV QBT_DOWNLOADS_PATH=/home/qbittorrent/downloads

# Run qBittorrent-nox
CMD ["qbittorrent-nox", "--profile=/home/qbittorrent"]
