#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_root"

if ! command -v tuist >/dev/null 2>&1; then
  if command -v mise >/dev/null 2>&1; then
    mise use -g tuist@latest
  elif command -v brew >/dev/null 2>&1; then
    brew install tuist
  else
    echo "Tuist is required. Install Mise or Homebrew, then rerun this script." >&2
    exit 1
  fi
fi

for target in SentinelOps AppShell AIInferenceEngine SyncEngine CoreDomain CoreUI SentinelOpsTests; do
  mkdir -p "Targets/$target/Sources" "Targets/$target/Resources"
done

tuist install
tuist generate --no-open
open SentinelOps.xcworkspace
