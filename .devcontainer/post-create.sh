#!/usr/bin/env bash
# Prepare the workspace after container creation. Non-fatal by design.
set -uo pipefail

git config --global --add safe.directory '*'
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${REPO}"

# settings.gradle asserts flutter.sdk is set here.
if [ -d android ] && ! grep -qs '^flutter.sdk=' android/local.properties 2>/dev/null; then
    echo "flutter.sdk=${FLUTTER_ROOT:-/opt/flutter}" >> android/local.properties
fi

# Register the Android docs MCP in the mounted Claude config if missing.
if command -v claude >/dev/null 2>&1 && command -v android-docs-mcp >/dev/null 2>&1; then
    claude mcp list 2>/dev/null | grep -q '^android-docs' || \
        claude mcp add android-docs --scope user -- android-docs-mcp || true
fi

# Drives the emulator over MCP; needs a booted device (.devcontainer/emulator.sh).
if command -v claude >/dev/null 2>&1 && command -v mcp-server-mobile >/dev/null 2>&1; then
    claude mcp list 2>/dev/null | grep -q '^mobile' || \
        claude mcp add mobile --scope user -- mcp-server-mobile || true
fi

flutter --version
flutter pub get || echo "==> 'flutter pub get' failed"

echo "workspace ready at ${REPO}"
