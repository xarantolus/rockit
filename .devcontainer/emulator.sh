#!/usr/bin/env bash
# Headless emulator lifecycle. Interaction (screenshots, taps, installing the
# app) is done through the mobile-mcp server, which needs a device that is
# already running.
#
#   emulator.sh start [avd]   boot headless and wait for it to come up
#   emulator.sh stop
#   emulator.sh status
set -uo pipefail

cmd=${1:-status}
avd=${2:-${AVD_NAME:-rockit}}
BOOT_TIMEOUT=${BOOT_TIMEOUT:-300}

case "$cmd" in
start)
    if [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then
        echo "emulator: /dev/kvm not accessible - run the container with --device /dev/kvm" >&2
        exit 2
    fi
    if adb shell getprop sys.boot_completed 2>/dev/null | grep -q 1; then
        echo "emulator: already running"
        exit 0
    fi

    nohup emulator -avd "$avd" \
        -no-window -no-audio -no-boot-anim -no-snapshot \
        -gpu swiftshader_indirect -netdelay none -netspeed full \
        > /tmp/emulator.log 2>&1 &

    adb wait-for-device
    waited=0
    until adb shell getprop sys.boot_completed 2>/dev/null | grep -q 1; do
        sleep 3
        waited=$((waited + 3))
        if [ "$waited" -ge "$BOOT_TIMEOUT" ]; then
            echo "emulator: did not boot within ${BOOT_TIMEOUT}s (see /tmp/emulator.log)" >&2
            exit 1
        fi
    done
    adb devices | grep emulator
    echo "emulator: booted in ${waited}s"
    ;;
stop)
    adb emu kill 2>/dev/null && echo "emulator: stopped" || echo "emulator: not running"
    ;;
status)
    adb devices | grep emulator || echo "emulator: not running"
    ;;
*)
    sed -n '2,9p' "$0"
    exit 2
    ;;
esac
