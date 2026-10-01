#!/usr/bin/env bash
# ==============================================================================
# build_android_sdl3.sh - Build Castlevania: Dawn of Sorrow for Android ARM64 (SDL3)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "${SCRIPT_DIR}/../runner" ]; then
    NDSRECOMP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
    ANDROID_DIR="${SCRIPT_DIR}"
else
    ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
    NDSRECOMP_DIR="${ROOT_DIR}/ndsrecomp"
    ANDROID_DIR="${ROOT_DIR}/android"
fi

# Android NDK and SDK detection
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/home/windroid/Android/Sdk}"
ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-${ANDROID_SDK_ROOT}/ndk/27.2.12479018}"

echo "==========================================================="
echo " Building Castlevania: Dawn of Sorrow (Android ARM64 + SDL3)"
echo "==========================================================="
echo "SDK: ${ANDROID_SDK_ROOT}"
echo "NDK: ${ANDROID_NDK_ROOT}"
echo "==========================================================="

# Ensure SDL3 is installed
if [ ! -f "${ANDROID_DIR}/installed-sdl3-arm64/lib/libSDL3.so" ]; then
    if [ ! -d "${ANDROID_DIR}/thirdparty/SDL3" ]; then
        echo "[0/4] Downloading SDL 3.2.8 source..."
        mkdir -p "${ANDROID_DIR}/thirdparty"
        git clone --depth 1 --branch release-3.2.8 https://github.com/libsdl-org/SDL.git "${ANDROID_DIR}/thirdparty/SDL3"
    fi

    echo "[0/4] Compiling SDL3 for Android ARM64..."
    cmake -S "${ANDROID_DIR}/thirdparty/SDL3" \
          -B "${ANDROID_DIR}/build-sdl3-arm64" \
          -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake" \
          -DANDROID_ABI=arm64-v8a \
          -DANDROID_PLATFORM=android-24 \
          -DANDROID_STL=c++_shared \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX="${ANDROID_DIR}/installed-sdl3-arm64" \
          -DSDL_SHARED=ON \
          -DSDL_STATIC=OFF \
          -DSDL_TEST=OFF
    cmake --build "${ANDROID_DIR}/build-sdl3-arm64" -j"$(nproc)"
    cmake --install "${ANDROID_DIR}/build-sdl3-arm64"
fi

# 1. Compile nds_runner for Android ARM64
echo "[1/4] Configuring & compiling native runner (libmain.so)..."
cmake -S "${NDSRECOMP_DIR}/runner" \
      -B "${NDSRECOMP_DIR}/runner/build-android-sdl3" \
      -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake" \
      -DANDROID_ABI=arm64-v8a \
      -DANDROID_PLATFORM=android-24 \
      -DANDROID_STL=c++_shared \
      -DCMAKE_BUILD_TYPE=Release \
      -DNDS_SDL_BACKEND=SDL3 \
      -DSDL3_DIR="${ANDROID_DIR}/installed-sdl3-arm64/lib/cmake/SDL3" \
      -DNDS_ENABLE_COMPUTE_RENDERER=OFF \
      -DNDS_ENABLE_PCAP_BACKEND=OFF \
      -DNDS_BOOTSTRAP_FIRMWARE=ON \
      -DNDS_TITLE_BANK_DIR="${NDSRECOMP_DIR}/generated" \
      -DNDS_TITLE_ROM_SHA1="9d4b6f7e4c473954c763d27c59c33f57b8b2f9f9"

cmake --build "${NDSRECOMP_DIR}/runner/build-android-sdl3" -j"$(nproc)"

# 2. Deploy native libraries into jniLibs
echo "[2/4] Deploying native libraries (libmain.so, libSDL3.so, libc++_shared.so)..."
JNILIBS_DIR="${ANDROID_DIR}/app/src/main/jniLibs/arm64-v8a"
mkdir -p "${JNILIBS_DIR}"

cp "${ANDROID_DIR}/installed-sdl3-arm64/lib/libSDL3.so" "${JNILIBS_DIR}/"
cp "${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" "${JNILIBS_DIR}/"

"${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" \
    --strip-unneeded \
    -o "${JNILIBS_DIR}/libmain.so" \
    "${NDSRECOMP_DIR}/runner/build-android-sdl3/libmain.so"

# 3. Synchronize assets
echo "[3/4] Synchronizing game assets..."
mkdir -p "${ANDROID_DIR}/app/src/main/assets"
cp "${NDSRECOMP_DIR}/game.toml" "${ANDROID_DIR}/app/src/main/assets/game.toml"

# 4. Assemble Android APK via Gradle
echo "[4/4] Assembling APK with Gradle..."
cd "${ANDROID_DIR}"
./gradlew assembleDebug

echo "==========================================================="
echo " Build Complete!"
echo " APK generated at:"
echo " ${ANDROID_DIR}/app/build/outputs/apk/debug/app-debug.apk"
echo "==========================================================="
