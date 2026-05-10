#!/bin/bash

# Exit on any error
set -e

echo "--- Updating Package Lists ---"
sudo apt update

echo "--- Installing Core Build Tools ---"
sudo apt install -y build-essential cmake ninja-build pkg-config

echo "--- Installing System Dependencies ---"
# We found that zlib and GL are already present but need dev headers
sudo apt install -y zlib1g-dev libgl-dev libgl1-mesa-dev libglvnd-dev libssl-dev

echo "--- Installing Qt6 Stack (including Private Headers) ---"
# qt6-base-private-dev is critical for qBittorrent's core logic
sudo apt install -y \
    qt6-base-dev \
    qt6-base-private-dev \
    libqt6svg6-dev \
    libqt6sql6-sqlite \
    qt6-httpserver-dev \
    qt6-tools-dev \
    qt6-l10n-tools

echo "--- Installing Library Dependencies ---"
# Based on your logs, these were found via PkgConfig/Boost
sudo apt install -y \
    libtorrent-rasterbar-dev \
    libboost-dev \
    libboost-system-dev

echo "--- Cleaning Old Build Artifacts ---"
if [ -d "build" ]; then
    rm -rf build
fi

echo "--- Configuring with ARM64-Specific Paths ---"
# We use explicit paths to bypass the search issues encountered with CMake 4.2
sudo cmake -G "Ninja" -B build \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DZLIB_LIBRARY=/usr/lib/aarch64-linux-gnu/libz.so \
  -DZLIB_INCLUDE_DIR=/usr/include \
  -DCMAKE_PREFIX_PATH=/usr/lib/aarch64-linux-gnu/cmake/Qt6 \
  -DCMAKE_POLICY_DEFAULT_CMP0167=OLD

echo "--- Build Configuration Complete ---"
echo "You can now run: cmake --build build -j\$(nproc)"

cmake --build build -j$(nproc)