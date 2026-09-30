#!/usr/bin/env python3
# ghidra_to_toml.py — Convert Ghidra function exports to ndsrecomp TOML config
#
# Usage: python3 tools/ghidra_to_toml.py <ghidra_functions.json> <output.toml> <cpu>
#
# This script converts the JSON output from Ghidra's export_functions.py
# into the TOML format expected by ndsrecomp's function finder.

import json
import sys
from pathlib import Path

def convert_json_to_toml(json_path, output_path, cpu_name):
    """Convert Ghidra JSON export to ndsrecomp TOML config."""

    with open(json_path, 'r') as f:
        functions = json.load(f)

    # Determine CPU mode based on cpu_name
    if cpu_name == "arm9":
        isa = "armv5te"
        default_mode = "arm"
    elif cpu_name == "arm7":
        isa = "armv4t"
        default_mode = "arm"
    else:
        raise ValueError(f"Unknown CPU: {cpu_name}")

    # Generate TOML content
    toml_lines = []
    toml_lines.append(f"# Auto-generated from {json_path}")
    toml_lines.append(f"# CPU: {cpu_name} ({isa})")
    toml_lines.append("")
    toml_lines.append("# ── Function entries from Ghidra analysis ──────────────")
    toml_lines.append(f"# {len(functions)} entries")
    toml_lines.append("")

    for func in functions:
        addr = func['addr']
        name = func['name']
        mode = func['mode']

        # Skip exception vectors and special entries (they're handled separately)
        if 'vector' in name.lower() or 'handler' in name.lower():
            continue

        toml_lines.append("[[entry_point]]")
        toml_lines.append(f'addr = {addr}')
        toml_lines.append(f'mode = "{mode}"')
        toml_lines.append(f'name = "{name}"')
        toml_lines.append("")

    # Add common exception vectors
    toml_lines.append("# ── Common exception vectors ─────────────────────────────")
    if cpu_name == "arm9":
        base = "0x02000000"
    else:
        base = "0x02380000"

    toml_lines.append("[[entry_point]]")
    toml_lines.append(f'addr = {base}')
    toml_lines.append('mode = "arm"')
    toml_lines.append('name = "reset_vector"')
    toml_lines.append('kind = "exception_vector"')
    toml_lines.append("")

    toml_lines.append("[[entry_point]]")
    toml_lines.append(f'addr = 0x{int(base, 16) + 0x18:X}')
    toml_lines.append('mode = "arm"')
    toml_lines.append('name = "irq_vector"')
    toml_lines.append('kind = "exception_vector"')
    toml_lines.append("")

    # Write output
    with open(output_path, 'w') as f:
        f.write('\n'.join(toml_lines))

    print(f"Converted {len(functions)} functions from {json_path} to {output_path}")
    print(f"CPU: {cpu_name} ({isa})")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 ghidra_to_toml.py <input.json> <output.toml> <cpu>")
        print("  cpu: 'arm9' or 'arm7'")
        sys.exit(1)

    json_path = sys.argv[1]
    output_path = sys.argv[2]
    cpu_name = sys.argv[3]

    convert_json_to_toml(json_path, output_path, cpu_name)
