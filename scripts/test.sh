#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ran=0
for d in tests/*/; do
  if ls "$d"*.odin >/dev/null 2>&1; then
    echo "== test $d"
    odin test "$d" -vet -collection:rico16=source
    ran=1
  fi
done
[ $ran -eq 1 ] || echo "no testable code yet, skipping"

