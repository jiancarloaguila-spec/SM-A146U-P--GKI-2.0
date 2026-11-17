#!/usr/bin/env bash
set -e

echo "=== [1/5] Setting up Environment & Toolchain Paths ==="
export ARCH=arm64
export SUBARCH=arm64

# Point to the downloaded AOSP Clang toolchain in your runner
export PATH="$(pwd)/clang/bin:$PATH"
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-android-
export CROSS_COMPILE_ARM32=arm-linux-androideabi-

# Number of parallel jobs for faster compilation
JOBS=$(nproc --all)
OUT_DIR="out"
mkdir -p "$OUT_DIR"

echo "=== [2/5] Integrating SukiSU Source ==="
# Check if SukiSU source folder exists in the kernel tree, if not clone it
# (Adjust target directory based on how your repo structures the drivers/kernel folder)
KERNEL_SRC="kernel-6.6" # or 'kernel' depending on your repo layout
if [ ! -d "$KERNEL_SRC/drivers/sukisu" ]; then
  echo "Cloning SukiSU source into kernel tree..."
  git clone https://github.com/SukiSU-Ultra/SukiSU-Ultra "$KERNEL_SRC/drivers/sukisu"
  
  # Inject SukiSU hooks into drivers/Kconfig and drivers/Makefile if not already present
  if ! grep -q "sukisu" "$KERNEL_SRC/drivers/Kconfig"; then
    echo 'source "drivers/sukisu/Kconfig"' >> "$KERNEL_SRC/drivers/Kconfig"
  fi
  if ! grep -q "sukisu" "$KERNEL_SRC/drivers/Makefile"; then
    echo 'obj-y += sukisu/' >> "$KERNEL_SRC/drivers/Makefile"
  fi
fi

echo "=== [3/5] Configuring Kernel with SukiSU Enabled ==="
cd "$KERNEL_SRC"

# Generate base GKI configuration
make O="../$OUT_DIR" gki_defconfig

# Enable SukiSU and required security/namespace options in .config
./scripts/config --file "../$OUT_DIR/.config" \
  -e CONFIG_SUKISU \
  -e CONFIG_KPROBES \
  -e CONFIG_HAVE_KPROBES \
  -e CONFIG_MODULES

# Old config refresh
make O="../$OUT_DIR" olddefconfig

echo "=== [4/5] Compiling Monolithic GKI Image ==="
make O="../$OUT_DIR" -j$JOBS Image

echo "=== [5/5] Build Complete! ==="
if [ -f "../$OUT_DIR/arch/arm64/boot/Image" ]; then
  echo "Success: Kernel Image generated at out/arch/arm64/boot/Image"
else
  echo "Error: Kernel Image compilation failed or output path mismatch."
  exit 1
fi
