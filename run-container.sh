#!/usr/bin/env bash
# Build the dev image and open a shell in it; arguments go to `podman run`.
set -euo pipefail

cd "$(dirname "$0")"
NAME=$(basename "$PWD")
IMAGE=$NAME-flutter-dev:latest
REPO=/workspaces/$NAME
CLAUDE_STATE="$HOME/claude-state/$NAME"
mkdir -p "$CLAUDE_STATE"

podman build -f .devcontainer/Dockerfile -t "$IMAGE" .

args=(
  -it --rm
  --net=host
  --security-opt label=disable
  -v "$PWD":"$REPO"
  -v "$NAME-gradle":/root/.gradle
  -v "$NAME-pub":/root/.pub-cache
  -v "$NAME-avd":/root/.android
  -v "$CLAUDE_STATE":/root/.claude
  -e CLAUDE_CONFIG_DIR=/root/.claude
  -w "$REPO"
)
if [ -e /dev/kvm ]; then
  [ -r /dev/kvm ] && [ -w /dev/kvm ] ||
    echo "warning: no access to /dev/kvm (join the kvm group and log in again); the emulator won't start" >&2
  args+=(--device /dev/kvm --group-add keep-groups)
fi
[ -d /dev/bus/usb ] && args+=(--cap-add SYS_RAWIO --cap-add MKNOD --device /dev/bus/usb)
[ -d "$HOME/.ssh" ] && args+=(-v "$HOME/.ssh":/root/.ssh)
[ -d "$HOME/.config/gh" ] && args+=(-v "$HOME/.config/gh":/root/.config/gh:ro)

exec podman run "${args[@]}" "$@" "$IMAGE" bash -c 'bash .devcontainer/post-create.sh; exec bash'
