#!/bin/bash
# Script de build para Android NDK com otimizações de performance
# Uso: ./build_android.sh /caminho/para/android-ndk

set -e

NDK_PATH="$1"
if [ -z "$NDK_PATH" ]; then
    echo "Erro: Especifique o caminho para o Android NDK"
    echo "Uso: $0 /caminho/para/android-ndk"
    exit 1
fi

if [ ! -d "$NDK_PATH" ]; then
    echo "Erro: Diretório NDK não encontrado: $NDK_PATH"
    exit 1
fi

# Configurações
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_ROOT/runner/build-android"
INSTALL_DIR="$PROJECT_ROOT/android_output"

echo "=== Build Android NDS Runner ==="
echo "NDK: $NDK_PATH"
echo "Build dir: $BUILD_DIR"
echo "Install dir: $INSTALL_DIR"
echo ""

# Limpar build anterior
rm -rf "$BUILD_DIR"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Configurar CMake com Android NDK
cmake -S "$PROJECT_ROOT/runner" -B "$BUILD_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-24 \
    -DANDROID_STL=c++_shared \
    -DCMAKE_BUILD_TYPE=Release \
    -DNDS_SDL_BACKEND=SDL2 \
    -DNDS_ENABLE_COMPUTE_RENDERER=OFF \
    -DNDS_ENABLE_PCAP_BACKEND=OFF \
    -DNDS_TITLE_BANK_DIR="$PROJECT_ROOT/generated" \
    -DNDS_TITLE_ROM_SHA1="9d4b6f7e4c473954c763d27c59c33f57b8b2f9f9" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

# Compilar
cmake --build "$BUILD_DIR" -j$(nproc)

# Instalar
cmake --install "$BUILD_DIR"

echo ""
echo "=== Build concluído com sucesso! ==="
echo "Binários instalados em: $INSTALL_DIR"
echo ""
echo "Bibliotecas geradas:"
ls -lh "$INSTALL_DIR/lib/"
echo ""
echo "Próximos passos:"
echo "1. Copie as bibliotecas .so para o seu projeto Android"
echo "2. Defina as variáveis de ambiente no seu código Java/Kotlin:"
echo "   NDS_3D_RENDERER=soft"
echo "   NDS_3D_THREADED=1"
echo "   NDS_CPU_FAST_POLL=1"
