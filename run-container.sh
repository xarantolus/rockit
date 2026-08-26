#!/usr/bin/env bash
# Build the dev image and drop into a shell with the repo mounted, Gradle/pub
# caches on volumes, and Claude Code state kept on the host.
set -euo pipefail

cd "$(dirname "$0")"
IMAGE=rockit-flutter-dev:latest
NAME=$(basename "$PWD")
REPO=/workspaces/$NAME
CLAUDE_STATE="$HOME/claude-state/$NAME"
mkdir -p "$CLAUDE_STATE"

podman build -f .devcontainer/Dockerfile -t "$IMAGE" .

args=(
  -it --rm
  # keep-id fails at create on this host's podman store; as root the default
  # rootless mapping already yields host-UID-owned files.
  --net=host
  -v "$PWD":"$REPO":Z
  -v "${NAME}-gradle":/root/.gradle
  -v "${NAME}-pub":/root/.pub-cache
  -e CLAUDE_CONFIG_DIR=/root/.claude
  --mount "type=bind,source=$CLAUDE_STATE,target=/root/.claude,consistency=cached"
  -w "$REPO"
)
if [ -d /dev/bus/usb ]; then
  args+=(--cap-add SYS_RAWIO --cap-add CAP_MKNOD --device /dev/bus/usb:/dev/bus/usb)
fi
[ -d "$HOME/.ssh" ] && args+=(--mount "type=bind,source=$HOME/.ssh,target=/root/.ssh,consistency=cached")
# gh credentials, so .ci-watch/ci-watch.sh can read Actions runs.
[ -d "$HOME/.config/gh" ] && args+=(--mount "type=bind,source=$HOME/.config/gh,target=/root/.config/gh,readonly")

exec podman run "${args[@]}" "$IMAGE" bash -c 'bash .devcontainer/post-create.sh; exec bash'
