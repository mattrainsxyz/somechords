#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/dekhenge-checks.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -parse-as-library -module-cache-path "$check_dir/modules" \
  "$project_dir/Dekhenge/Utilities/PianoNote.swift" \
  "$project_dir/Dekhenge/Models/Song.swift" \
  "$project_dir/Dekhenge/Models/Chord.swift" \
  "$project_dir/Dekhenge/App/NotebookStore.swift" \
  "$project_dir/Tests/PersistenceChecks.swift" \
  -o "$check_dir/persistence-checks"
"$check_dir/persistence-checks"
