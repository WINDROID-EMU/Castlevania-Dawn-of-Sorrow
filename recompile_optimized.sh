#!/bin/bash
# Script de Recompilação Otimizada - Castlevania: Dawn of Sorrow
# Aplica: ARM7 WRAM + ARM7 Main + ARM9 Main + ARM9 ITCM + Overlays Exclusivos 0000 e 0001

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECOMPILER="$PROJECT_ROOT/recompiler/build/nds_recompile"
GENERATED="$PROJECT_ROOT/generated"
EXTRACTED="$PROJECT_ROOT/extracted"
CONFIG="$PROJECT_ROOT/config"

echo "=========================================================="
echo " Recompilação Completa e Otimizada: Dawn of Sorrow"
echo "=========================================================="

mkdir -p "$GENERATED"
rm -f "$GENERATED"/castlevania_arm*.c "$GENERATED"/castlevania_arm*.h

echo ""
echo "[1/6] Recompilando ARM7 WRAM (Elimina quedas no áudio/sincronia)..."
"$RECOMPILER" \
    --config "$CONFIG/arm7_wram.toml" \
    --bin "$EXTRACTED/arm7.bin" \
    --out "$GENERATED" \
    --bank castlevania_arm7_wram \
    --shards 2

echo ""
echo "[2/6] Recompilando ARM7 Main..."
"$RECOMPILER" \
    --config "$CONFIG/arm7.toml" \
    --bin "$EXTRACTED/arm7.bin" \
    --out "$GENERATED" \
    --bank castlevania_arm7 \
    --shards 2

echo ""
echo "[3/6] Recompilando ARM9 Main (com todas as funções capturadas em 10 shards rápidos)..."
"$RECOMPILER" \
    --config "$CONFIG/arm9.toml" \
    --bin "$EXTRACTED/arm9.bin" \
    --out "$GENERATED" \
    --bank castlevania_arm9 \
    --shards 10

echo ""
echo "[4/6] Recompilando ARM9 ITCM (Memória ultrarrápida do loop de física/render)..."
"$RECOMPILER" \
    --config "$CONFIG/arm9_itcm.toml" \
    --bin "$EXTRACTED/arm9.bin" \
    --out "$GENERATED" \
    --bank castlevania_arm9_itcm \
    --shards 2

echo ""
echo "[5/6] Recompilando ARM9 Overlay 0000 (Motor central exclusivo de gameplay: 7.395 funções)..."
"$RECOMPILER" \
    --config "$CONFIG/arm9_overlay_0000.toml" \
    --bin "$EXTRACTED/overlays/overlay_0000.bin" \
    --out "$GENERATED" \
    --bank castlevania_arm9_overlay_0000 \
    --shards 4

echo ""
echo "[6/6] Recompilando ARM9 Overlay 0001 (Módulo auxiliar permanente: 1.696 funções)..."
"$RECOMPILER" \
    --config "$CONFIG/arm9_overlay_0001.toml" \
    --bin "$EXTRACTED/overlays/overlay_0001.bin" \
    --out "$GENERATED" \
    --bank castlevania_arm9_overlay_0001 \
    --shards 2

echo ""
echo "=========================================================="
echo " Recompilação C Concluída! Compilando nds_runner..."
echo "=========================================================="

cmake -B "$PROJECT_ROOT/runner/build-pc" "$PROJECT_ROOT/runner"
cmake --build "$PROJECT_ROOT/runner/build-pc" -j$(nproc)

echo ""
echo "=========================================================="
echo " SUCESSO! O executável otimizado foi compilado em:"
echo " $PROJECT_ROOT/runner/build-pc/nds_runner"
echo "=========================================================="
