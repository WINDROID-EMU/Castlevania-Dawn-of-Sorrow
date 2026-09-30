#!/usr/bin/env bash
# ghidra/import_castlevania.sh — headless import + analyze + seed-export of
# Castlevania: Dawn of Sorrow. Adapted from import_bios.sh for full NDS ROMs.
#
# Usage: bash ghidra/import_castlevania.sh <GHIDRA_INSTALL_DIR>
#   e.g. bash ghidra/import_castlevania.sh /c/ghidra_11.0
#
# Produces ghidra/Castlevania.gpr and generated/castlevania_function_starts_*.json

set -euo pipefail

GHIDRA="${1:-}"
if [ -z "$GHIDRA" ]; then
    echo "usage: import_castlevania.sh <GHIDRA_INSTALL_DIR>" >&2
    exit 2
fi

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HEADLESS="$GHIDRA/support/analyzeHeadless"
[ -x "$HEADLESS" ] || HEADLESS="$GHIDRA/support/analyzeHeadless.bat"

PROJ_DIR="$REPO_ROOT/ghidra"
PROJ_NAME="Castlevania"
SCRIPT_DIR="$REPO_ROOT/ghidra"
ROM_PATH="/media/windroid/SSD KING/Recomp-NDS/Castlevania - Dawn of Sorrow .nds"
OUT="$REPO_ROOT/generated"
mkdir -p "$OUT"

if [ ! -f "$ROM_PATH" ]; then
    echo "ERROR: ROM not found at $ROM_PATH" >&2
    exit 1
fi

# NDS ROM structure:
# - ARM9 binary starts at offset 0x20 (after header)
# - ARM9 loads at 0x02000000 in memory
# - ARM7 binary starts after ARM9
# - ARM7 loads at 0x03800000 in memory
# We'll need to extract the binaries first

echo "==> Extracting ARM9 and ARM7 binaries from ROM..."

# Create temp directory for extraction
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Use Python to extract binaries (more reliable than bash for binary ops)
python3 -c "
import struct
import sys

rom_path = '/media/windroid/SSD KING/Recomp-NDS/Castlevania - Dawn of Sorrow .nds'
temp_dir = '$TEMP_DIR'

with open(rom_path, 'rb') as f:
    # Read NDS header
    header = f.read(0x200)

    # Parse header
    arm9_rom_offset = struct.unpack('<I', header[0x20:0x24])[0]
    arm9_entry_addr = struct.unpack('<I', header[0x24:0x28])[0]
    arm9_ram_addr = struct.unpack('<I', header[0x28:0x2C])[0]
    arm9_size = struct.unpack('<I', header[0x2C:0x30])[0]

    arm7_rom_offset = struct.unpack('<I', header[0x30:0x34])[0]
    arm7_entry_addr = struct.unpack('<I', header[0x34:0x38])[0]
    arm7_ram_addr = struct.unpack('<I', header[0x38:0x3C])[0]
    arm7_size = struct.unpack('<I', header[0x3C:0x40])[0]

    print(f'ARM9: ROM offset 0x{arm9_rom_offset:X}, RAM 0x{arm9_ram_addr:X}, Size 0x{arm9_size:X}, Entry 0x{arm9_entry_addr:X}')
    print(f'ARM7: ROM offset 0x{arm7_rom_offset:X}, RAM 0x{arm7_ram_addr:X}, Size 0x{arm7_size:X}, Entry 0x{arm7_entry_addr:X}')

    # Extract ARM9 binary
    f.seek(arm9_rom_offset)
    arm9_data = f.read(arm9_size)
    with open(f'{temp_dir}/arm9.bin', 'wb') as out:
        out.write(arm9_data)

    # Extract ARM7 binary
    f.seek(arm7_rom_offset)
    arm7_data = f.read(arm7_size)
    with open(f'{temp_dir}/arm7.bin', 'wb') as out:
        out.write(arm7_data)

    print(f'Extracted binaries to {temp_dir}')
"

import_one() {
    local file="$1" lang="$2" base="$3" tag="$4"
    echo "==> importing $file ($lang @ $base)"
    "$HEADLESS" "$PROJ_DIR" "$PROJ_NAME" \
        -import "$file" \
        -processor "$lang" \
        -loader BinaryLoader -loader-baseAddr "$base" \
        -scriptPath "$SCRIPT_DIR" \
        -postScript ExportFunctions.java "$OUT/castlevania_function_starts_$tag.json" \
        -overwrite
}

# ARM9 — ARM946E-S / ARMv5TE, loads at 0x02000000
import_one "$TEMP_DIR/arm9.bin" "ARM:LE:32:v5t" "0x02000000" "arm9"

# ARM7 — ARM7TDMI / ARMv4T, loads at 0x02380000 (Castlevania DoS ARM7 RAM load address)
import_one "$TEMP_DIR/arm7.bin" "ARM:LE:32:v4t" "0x02380000" "arm7"

echo "==> done. seeds in $OUT/castlevania_function_starts_arm9.json and _arm7.json"
