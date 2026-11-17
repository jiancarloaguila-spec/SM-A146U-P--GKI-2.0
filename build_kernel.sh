#!/usr/bin/env bash
set -e

echo "=== [1/3] Integrating SukiSU-Ultra ==="
export PATH="$(pwd)/clang/bin:$PATH"

# Run SukiSU-Ultra's official integration script inside kernel-6.6
cd kernel-6.6
if [ ! -d "drivers/kernelsu" ]; then
  echo "Running SukiSU-Ultra setup.sh..."
  curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s main
fi
cd ..

echo "=== [2/3] Running GKI Workspace Build ==="
cd kernel
# Point BUILD_CONFIG directly to kernel-6.6/build.config.gki.aarch64
BUILD_CONFIG=kernel-6.6/build.config.gki.aarch64 ./build/build.sh

echo "=== [3/3] Build Finished ==="
cd ..
if [ -f out/kernel-6.6/dist/Image ] || [ -f out/arch/arm64/boot/Image ]; then
  echo "Success: Compiled GKI Image found!"
else
  echo "Checking output locations for Image..."
  find . -name "Image"
fi
