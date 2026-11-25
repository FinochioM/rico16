#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:-debug}"
out="build/$mode"
mkdir -p "$out"
ext=""; case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ext=".exe";; esac
if [ "$mode" = release ]; then flags="-o:speed -vet -strict-style"
else flags="-debug -vet"; fi

if ! ls source/console/*.odin >/dev/null 2>&1; then echo "no code yet"; exit 0; fi
odin build source/console -out:"$out/rico16$ext" $flags -collection:rico16=source
echo "built $out/rico16$ext"
