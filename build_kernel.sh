# ====================================================================
# SukiSU Ultra LKM Injection Extension
# ====================================================================
echo "[+] Initializing SukiSU Ultra LKM Extension..."

# 1. Clone SukiSU Ultra source code if not already present
if [ ! -d "suki-src" ]; then
    git clone --depth=1 https://github.com suki-src
fi

# 2. Derive build definitions from your existing GKI build setup
# Assumes your script sets $OUT_DIR or a target build output directory. 
# Adjust 'kernel-6.6' to matching path if your script relies on an absolute path.
KERNEL_SRC_DIR="$(pwd)/kernel-6.6"
OUTPUT_MODULE_DIR="$(pwd)/out/suki_module"

mkdir -p "$OUTPUT_MODULE_DIR"

echo "[+] Compiling SukiSU out-of-tree LKM against Kernel 6.6 tree..."
make -C "$KERNEL_SRC_DIR" \
     O="$(pwd)/out" \
     ARCH=arm64 \
     CC=clang \
     CROSS_COMPILE=aarch64-linux-gnu- \
     CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
     M="$(pwd)/suki-src/kernel" \
     modules

# 3. Collect the generated .ko driver
find suki-src/kernel/ -name "*.ko" -exec cp {} "$OUTPUT_MODULE_DIR" \;
echo "[+] SukiSU Ultra module compilation finished!"
