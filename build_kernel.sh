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

# Ensure KPROBES, KSU, and Mountify support flags are enabled
./scripts/config --file "$OUT_DIR/.config" \
  -e CONFIG_KSU \
  -e CONFIG_KPROBES \
  -e CONFIG_HAVE_KPROBES \
  -e CONFIG_KPROBE_EVENTS \
  -e CONFIG_OVERLAY_FS \
  -e CONFIG_TMPFS_XATTR \
  -e CONFIG_TMPFS_POSIX_ACL \
  -e CONFIG_KALLSYMS \
  -e CONFIG_KALLSYMS_ALL \
  -e CONFIG_KPM

# Nuke Samsung Knox and Security features to prevent bootloops on SM-A146P
echo "Disabling Samsung security features and Knox..."
./scripts/config --file "$OUT_DIR/.config" \
  --disable CONFIG_UH \
  --disable CONFIG_UH_RKP \
  --disable CONFIG_UH_LKMAUTH \
  --disable CONFIG_UH_LKM_BLOCK \
  --disable CONFIG_RKP \
  --disable CONFIG_RKP_CFP_JOPP \
  --disable CONFIG_RKP_CFP_ROPP \
  --disable CONFIG_RKP_CFP \
  --disable CONFIG_SECURITY_DEFEX \
  --disable CONFIG_PROCA \
  --disable CONFIG_FIVE \
  --disable CONFIG_KDP \
  --disable CONFIG_KDP_NS \
  --disable CONFIG_KNOX_NCM

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
