#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_root"

for tool in xcodegen swiftlint; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool. Install it with: brew install $tool" >&2
    exit 1
  fi
done

mkdir -p Sources/SentinelOps Resources Packages Tests/SentinelOpsTests Tests/SentinelOpsUITests
xcodegen generate --spec project.yml --project SentinelOps.xcodeproj

workspace_path="SentinelOps.xcworkspace"
mkdir -p "$workspace_path"
printf '%s\n' \
  '<?xml version="1.0" encoding="UTF-8"?>' \
  '<Workspace version="1.0">' \
  '  <FileRef location="group:SentinelOps.xcodeproj"/>' \
  '  <FileRef location="group:Packages/SentinelOps"/>' \
  '</Workspace>' \
  > "$workspace_path/contents.xcworkspacedata"

echo "Generated SentinelOps.xcodeproj and SentinelOps.xcworkspace."
