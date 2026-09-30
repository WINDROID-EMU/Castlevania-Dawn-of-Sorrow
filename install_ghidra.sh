#!/bin/bash
# Script helper para instalar e executar análise com Ghidra

set -e

GHIDRA_ZIP="$1"
INSTALL_DIR="/home/windroid/ghidra"

if [ -z "$GHIDRA_ZIP" ]; then
    echo "Uso: $0 <caminho/para/ghidra.zip>"
    echo ""
    echo "Exemplo:"
    echo "  $0 ~/Downloads/ghidra_11.2.1_PUBLIC_20241107.zip"
    exit 1
fi

if [ ! -f "$GHIDRA_ZIP" ]; then
    echo "ERRO: Arquivo não encontrado: $GHIDRA_ZIP"
    exit 1
fi

echo "=== Instalando Ghidra ==="
echo "ZIP: $GHIDRA_ZIP"
echo "Instalando em: $INSTALL_DIR"
echo ""

# Criar diretório se não existir
mkdir -p "$INSTALL_DIR"

# Extrair
echo "Extraindo Ghidra (isso pode levar alguns minutos)..."
unzip -q "$GHIDRA_ZIP" -d "$INSTALL_DIR"

# Encontrar o diretório extraído
GHIDRA_DIR=$(find "$INSTALL_DIR" -maxdepth 1 -type d -name "ghidra_*" | head -1)

if [ -z "$GHIDRA_DIR" ]; then
    echo "ERRO: Não foi possível encontrar o diretório do Ghidra após extração"
    exit 1
fi

echo "✓ Ghidra extraído em: $GHIDRA_DIR"
echo ""

# Verificar analyzeHeadless
HEADLESS="$GHIDRA_DIR/support/analyzeHeadless"
if [ ! -f "$HEADLESS" ]; then
    HEADLESS="$GHIDRA_DIR/support/analyzeHeadless.bat"
fi

if [ ! -f "$HEADLESS" ]; then
    echo "ERRO: analyzeHeadless não encontrado em $GHIDRA_DIR/support/"
    exit 1
fi

echo "✓ analyzeHeadless encontrado: $HEADLESS"
echo ""

# Executar análise
PROJECT_ROOT="/media/windroid/SSD KING/Recomp-NDS/ndsrecomp"
cd "$PROJECT_ROOT"

echo "=== Executando análise do Castlevania ==="
./ghidra/analyze_castlevania.sh "$GHIDRA_DIR"

echo ""
echo "=== Análise concluída! ==="
echo "Configuração gerada: $PROJECT_ROOT/castlevania_dos.toml"
