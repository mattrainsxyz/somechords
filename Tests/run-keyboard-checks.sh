#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/dekhenge-keyboard-checks.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -parse-as-library -module-cache-path "$check_dir/modules" \
  "$project_dir/Dekhenge/Utilities/PianoNote.swift" \
  "$project_dir/Dekhenge/Utilities/PianoKeyboardLayout.swift" \
  "$project_dir/Tests/KeyboardChecks.swift" \
  -o "$check_dir/keyboard-checks"
"$check_dir/keyboard-checks"
