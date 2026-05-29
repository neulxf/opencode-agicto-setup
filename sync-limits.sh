#!/usr/bin/env bash
# Sync context/output limits from models.dev cache into opencode.json
# Only updates models that have a ¥ price in their name field (AGICTO models)
# Cost values are preserved from the user's AGICTO pricing, not overwritten

set -uo pipefail

CONFIG="${HOME}/.config/opencode/opencode.json"
CACHE="${HOME}/.cache/opencode/models.json"

if [ ! -f "$CACHE" ]; then
    echo "models cache not found at $CACHE"
    echo "Run opencode first to download it"
    exit 1
fi

python3 - "$CONFIG" "$CACHE" << 'PYEOF'
import json, os, re, sys

config_path, cache_path = sys.argv[1], sys.argv[2]

with open(cache_path) as f:
    catalog = json.load(f)

lookup = {}
for pid, prov in catalog.items():
    if not isinstance(prov, dict) or "models" not in prov:
        continue
    for mid, meta in prov["models"].items():
        if mid not in lookup:
            lookup[mid] = meta

with open(config_path) as f:
    config = json.load(f)

updated = 0
not_found = []

for pname, prov in config.get("provider", {}).items():
    for mid, model in prov.get("models", {}).items():
        meta = lookup.get(mid)
        if not meta:
            not_found.append(mid)
            continue

        limit = meta.get("limit", {})
        if limit:
            new_limit = {}
            for k in ["context", "output", "input"]:
                if k in limit:
                    new_limit[k] = limit[k]
            if new_limit:
                model["limit"] = new_limit

        if "cost" not in model:
            cost = meta.get("cost", {})
            if cost:
                model["cost"] = {
                    "input": cost.get("input", 0),
                    "output": cost.get("output", 0),
                }

        for k in ["family", "reasoning", "tool_call", "temperature"]:
            if k in meta:
                model[k] = meta[k]

        updated += 1

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)

print(f"Updated {updated} models with context/output limits")
if not_found:
    print(f"Skipped ({len(not_found)} not in catalog): {', '.join(not_found)}")
PYEOF
