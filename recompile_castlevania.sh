#!/bin/bash
# Script para recompilar Castlevania: Dawn of Sorrow
# Utiliza os binários extraídos arm9.bin e arm7.bin conforme padrão NDS Recomp

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARM9_BIN="$PROJECT_ROOT/extracted/arm9.bin"
ARM7_BIN="$PROJECT_ROOT/extracted/arm7.bin"
ARM9_CONFIG="$PROJECT_ROOT/config/arm9.toml"
ARM7_CONFIG="$PROJECT_ROOT/config/arm7.toml"
GENERATED_DIR="$PROJECT_ROOT/generated"

echo "=== Recompilando Castlevania: Dawn of Sorrow ==="
echo "ARM9 Binário: $ARM9_BIN"
echo "ARM7 Binário: $ARM7_BIN"
echo "Output: $GENERATED_DIR"
echo ""

# Verificar se os binários existem
if [ ! -f "$ARM9_BIN" ] || [ ! -f "$ARM7_BIN" ]; then
    echo "ERRO: Binários extraídos não encontrados em $PROJECT_ROOT/extracted"
    exit 1
fi

# Etapa 1: Compilar o recompilador (se necessário)
echo "=== Etapa 1: Verificando o recompilador ==="
if [ ! -d "$PROJECT_ROOT/recompiler/build" ]; then
    cmake -G Ninja -B "$PROJECT_ROOT/recompiler/build" "$PROJECT_ROOT/recompiler"
    cmake --build "$PROJECT_ROOT/recompiler/build"
    echo "✓ Recompilador compilado com sucesso"
else
    echo "✓ Recompilador pronto"
fi

# Etapa 2: Limpar bancos anteriores do jogo
mkdir -p "$GENERATED_DIR"
rm -f "$GENERATED_DIR"/castlevania_arm*.c "$GENERATED_DIR"/castlevania_arm*.h

# Etapa 3: Recompilar ARM9 do Castlevania (4 shards)
echo ""
echo "=== Etapa 2: Recompilando ARM9 do Castlevania ==="
"$PROJECT_ROOT/recompiler/build/nds_recompile" \
    --config "$ARM9_CONFIG" \
    --bin "$ARM9_BIN" \
    --out "$GENERATED_DIR" \
    --bank castlevania_arm9 \
    --shards 4

# Etapa 4: Recompilar ARM7 do Castlevania (2 shards)
echo ""
echo "=== Etapa 3: Recompilando ARM7 do Castlevania ==="
"$PROJECT_ROOT/recompiler/build/nds_recompile" \
    --config "$ARM7_CONFIG" \
    --bin "$ARM7_BIN" \
    --out "$GENERATED_DIR" \
    --bank castlevania_arm7 \
    --shards 2

echo ""
echo "=== Recompilação concluída com sucesso! ==="
echo "Bancos gerados em: $GENERATED_DIR"
ls -lh "$GENERATED_DIR"/castlevania_arm*
