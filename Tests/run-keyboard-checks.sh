#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/somechords-keyboard-checks.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -parse-as-library -module-cache-path "$check_dir/modules" \
  "$project_dir/somechords/Utilities/PianoNote.swift" \
  "$project_dir/somechords/Utilities/PianoKeyboardLayout.swift" \
  "$project_dir/Tests/KeyboardChecks.swift" \
  -o "$check_dir/keyboard-checks"
"$check_dir/keyboard-checks"
