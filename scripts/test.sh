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

if ls source/console/*.odin >/dev/null 2>&1; then
  echo "== smoke source/console (nil backend)"
  ext=""; case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ext=".exe";; esac
  mkdir -p build/test
  odin build source/console -out:"build/test/rico16_nil$ext" -debug -vet \
      -collection:rico16=source -define:RICO_BACKEND=nil
  "./build/test/rico16_nil$ext"
  echo "console ran headless ok"
fi
