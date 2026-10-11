#!/usr/bin/env bash
# Build the distributable NoDurability mod archive from main.lua.
set -euo pipefail

cd "$(dirname "$0")"
OUT_ROOT="${OUT:-NoDurability}"
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT

mkdir "$staging/$OUT_ROOT"
printf '%s\n' "$OUT_ROOT" > "$staging/$OUT_ROOT/enabled.txt"
mkdir "$staging/$OUT_ROOT/scripts"
cp main.lua "$staging/$OUT_ROOT/scripts/main.lua"

OUT="$OUT_ROOT.zip"
(cd "$staging" && zip -q -r "$staging/$OUT" "$OUT_ROOT")
mv "$staging/$OUT" .
echo "built $(pwd)/$OUT"
