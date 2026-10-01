#!/usr/bin/env python3
"""Ingest real-time Tier-3 misses captured via ADB logcat directly into bank TOMLs."""

import subprocess
import re
import json
import collections
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
CONFIG_DIR = ROOT_DIR / "config"
EXTRACTED_DIR = ROOT_DIR / "extracted"

def main():
    print("Reading ADB logcat for CastlevaniaT3 misses...")
    try:
        out = subprocess.check_output(['adb', 'logcat', '-d', '-s', 'CastlevaniaT3'], timeout=10).decode('utf-8', errors='replace')
    except Exception as e:
        print(f"Error reading logcat: {e}")
        return

    lines = [l for l in out.splitlines() if 'NEW TIER3 MISS' in l]
    print(f"Found {len(lines)} log lines with Tier-3 misses.")

    misses = set()
    for l in lines:
        m = re.search(r'cpu=(\d+)\s+pc=(0x[0-9a-fA-F]+)\s+thumb=(\d+)\s+kind=(\d+)\s+caller=(0x[0-9a-fA-F]+)', l)
        if m:
            cpu = int(m.group(1))
            pc = int(m.group(2), 16)
            thumb = int(m.group(3))
            misses.add((cpu, pc, thumb))

    print(f"Total unique misses: {len(misses)}")

    with open(EXTRACTED_DIR / "overlays.json") as f:
        ovs = json.load(f)

    # Map each miss to its target TOML file
    categories = collections.defaultdict(list)
    for cpu, pc, thumb in sorted(misses):
        mode_str = "thumb" if thumb else "arm"
        target_toml = None
        if cpu == 0:
            if 0x02000000 <= pc < 0x020C0000:
                target_toml = CONFIG_DIR / "arm9.toml"
            elif 0x01FF8000 <= pc < 0x02000000 or 0x01F00000 <= pc < 0x01F80000:
                target_toml = CONFIG_DIR / "arm9_itcm.toml"
            else:
                for ov in ovs:
                    load = int(ov['load_address'], 16)
                    size = ov['ram_size']
                    if load <= pc < load + size:
                        if ov['id'] == 0:
                            target_toml = CONFIG_DIR / "arm9_overlay_0000.toml"
                        elif ov['id'] == 1:
                            target_toml = CONFIG_DIR / "arm9_overlay_0001.toml"
                        break
        elif cpu == 1:
            if 0x037F0000 <= pc < 0x03810000:
                target_toml = CONFIG_DIR / "arm7_wram.toml"
            elif 0x02380000 <= pc < 0x023A0000:
                target_toml = CONFIG_DIR / "arm7.toml"

        if target_toml and target_toml.exists():
            categories[target_toml].append((pc, mode_str))
        else:
            print(f"Warning: no TOML target found for pc={hex(pc)} cpu={cpu}")

    total_added = 0
    for toml_path, entries in categories.items():
        content = toml_path.read_text(encoding="utf-8")
        existing_addrs = set()
        for m in re.finditer(r'addr\s*=\s*(0x[0-9a-fA-F]+|\d+)', content):
            raw = m.group(1)
            val = int(raw, 16) if raw.startswith("0x") else int(raw)
            existing_addrs.add(val)

        new_blocks = []
        for pc, mode_str in entries:
            if pc in existing_addrs:
                continue
            existing_addrs.add(pc)
            hex_str = f"0x{pc:08X}"
            name_str = f"FUN_{pc:08x}"
            block = f"\n[[entry_point]]\naddr = {hex_str}\nmode = \"{mode_str}\"\nname = \"{name_str}\"\n"
            new_blocks.append(block)

        if new_blocks:
            print(f"Adding {len(new_blocks)} new entry points to {toml_path.name}...")
            with open(toml_path, "a", encoding="utf-8") as f:
                f.write("".join(new_blocks))
            total_added += len(new_blocks)
        else:
            print(f"All {len(entries)} entry points already present in {toml_path.name}.")

    print(f"Ingestion complete: {total_added} new static entry points added across configs.")

if __name__ == "__main__":
    main()
