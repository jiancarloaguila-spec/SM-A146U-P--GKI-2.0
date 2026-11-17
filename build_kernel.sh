#!/usr/bin/env bash
set -e

echo "=== [1/3] Integrating SukiSU-Ultra ==="
export PATH="$(pwd)/clang/bin:$PATH"

# Clone SukiSU-Ultra directly into the kernel-6.6 driver directory if missing
if [ ! -d "kernel-6.6/drivers/sukisu" ]; then
  echo "Cloning SukiSU-Ultra into kernel source..."
  git clone https://github.com/SukiSU-Ultra/SukiSU-Ultra kernel-6.6/drivers/sukisu
  
  # Hook SukiSU into Kconfig and Makefile so the compiler picks it up
  if ! grep -q "sukisu" kernel-6.6/drivers/Kconfig; then
    echo 'source "drivers/sukisu/Kconfig"' >> kernel-6.6/drivers/Kconfig
  fi
  if ! grep -q "sukisu" kernel-6.6/drivers/Makefile; then
    echo 'obj-y += sukisu/' >> kernel-6.6/drivers/Makefile
  fi
fi

echo "=== [2/3] Running GKI Workspace Build ==="
cd kernel
# Execute the build script using the workspace environment
BUILD_CONFIG=common/build.config.gki.aarch64 ./build/build.sh || ./build/build.sh

echo "=== [3/3] Build Finished ==="
cd ..
if [ -f out/arch/arm64/boot/Image ] || [ -f out/kernel-6.6/arch/arm64/boot/Image ]; then
  echo "Success: Compiled GKI Image found!"
else
  echo "Checking alternative paths for Image..."
  find . -name "Image"
fi
