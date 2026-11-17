#!/usr/bin/env bash
set -e

echo "=== [1/3] Integrating SukiSU-Ultra ==="
export PATH="$(pwd)/clang/bin:$PATH"

cd kernel-6.6
if [ ! -d "drivers/kernelsu" ]; then
  echo "Running SukiSU-Ultra setup.sh..."
  curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s main
fi

echo "=== [2/3] Configuring & Compiling GKI 6.6 Kernel ==="
OUT_DIR="../out"
mkdir -p "$OUT_DIR"

# Generate base GKI arm64 config using Clang/LLVM
make O="$OUT_DIR" ARCH=arm64 LLVM=1 LLVM_IAS=1 gki_defconfig

# Ensure KPROBES and KSU flags are enabled for GKI 2.0
./scripts/config --file "$OUT_DIR/.config" \
  -e CONFIG_KSU \
  -e CONFIG_KPROBES \
  -e CONFIG_HAVE_KPROBES \
  -e CONFIG_KPROBE_EVENTS

make O="$OUT_DIR" ARCH=arm64 LLVM=1 LLVM_IAS=1 olddefconfig

# Compile the monolithic GKI kernel Image
make O="$OUT_DIR" ARCH=arm64 LLVM=1 LLVM_IAS=1 -j$(nproc --all) Image

echo "=== [3/3] Build Finished ==="
cd ..
if [ -f "out/arch/arm64/boot/Image" ]; then
  echo "Success: Compiled GKI Image found at out/arch/arm64/boot/Image!"
else
  echo "Error: Image compilation failed."
  exit 1
fi
