#!/usr/bin/env bash
#
# Verify a developer-handbook.md has the required canonical section titles.
# Usage: bash leastudios-dev-tools/bin/check-handbook.sh <path-to-handbook>
#
# Required section TITLES (numbering is renumbered per-plugin so ignored):
#   Overview, Architecture, Development Setup, Hooks Reference,
#   Hook Execution Order, Testing, Release Process, Where to Read More
#
# Exits 0 if all required sections present, 1 otherwise.

set -euo pipefail

handbook="${1:-}"
if [[ -z "$handbook" || ! -f "$handbook" ]]; then
  echo "usage: $0 <path-to-developer-handbook.md>" >&2
  exit 2
fi

required=(
  "Overview"
  "Architecture"
  "Development Setup"
  "Hooks Reference"
  "Hook Execution Order"
  "Testing"
  "Release Process"
  "Where to Read More"
)

missing=()
for section in "${required[@]}"; do
  # Match "## N. Section Name" or "## Section Name" — N may be any digits.
  if ! grep -Eq "^## ([0-9]+\. )?${section}( |$)" "$handbook"; then
    missing+=("$section")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo "FAIL: $handbook is missing required section(s):" >&2
  for s in "${missing[@]}"; do
    echo "  - $s" >&2
  done
  exit 1
fi

echo "OK: $handbook has all 8 required sections."
