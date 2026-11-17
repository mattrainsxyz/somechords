#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/somechords-checks.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -parse-as-library -module-cache-path "$check_dir/modules" \
  "$project_dir/somechords/Utilities/PianoNote.swift" \
  "$project_dir/somechords/Utilities/ChordDraft.swift" \
  "$project_dir/somechords/Models/SongChordEditing.swift" \
  "$project_dir/somechords/Models/Song.swift" \
  "$project_dir/somechords/Models/Chord.swift" \
  "$project_dir/somechords/App/NotebookStore.swift" \
  "$project_dir/Tests/PersistenceChecks.swift" \
  -o "$check_dir/persistence-checks"
"$check_dir/persistence-checks"
"$check_dir/persistence-checks" seed-process "$check_dir/relaunch.store"
"$check_dir/persistence-checks" verify-process "$check_dir/relaunch.store"
