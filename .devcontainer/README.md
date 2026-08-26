# Dev container (Flutter + Android)

A self-contained Android build environment for this app, plus the Claude Code
CLI so an agent can work inside it.

## What's in the image

| Component | Version |
| --- | --- |
| Flutter | 3.47.1 stable (Dart 3.13.1) |
| JDK | 17 (headless) — required by AGP 9 / Gradle 9 |
| Android SDK | platforms 36 + 34, build-tools 36.0.0 + 34.0.0, platform-tools |
| Node | 20 |
| Claude Code | latest at build time (`claude` on `PATH`) |

Base image is `ubuntu:24.04`. Android build artifacts are pre-cached
(`flutter precache --android`), so the first build in a fresh container doesn't
re-download them.

`flutter doctor` reports "Android license status unknown": recent command-line
tools dropped `sdkmanager --licenses`, and the check is stale. Builds work.

## Running it

VS Code: "Reopen in Container". Otherwise:

```sh
./run-container.sh
```

The container runs as **root**; with rootless podman the default mapping keeps
files owned by your host user. It deliberately avoids `--userns=keep-id`, which
fails at create on some podman stores, and would otherwise run as a UID that
does not own `/root` or the cache volumes.

Flutter's "running as root" warning is suppressed by the `/.dockerenv` marker
the image creates — podman doesn't add it, and Flutter uses it to detect that
root is expected here.

## Persistence

- Claude Code state is bind-mounted to `/root/.claude` with
  `CLAUDE_CONFIG_DIR=/root/.claude`, so sessions and config survive rebuilds.
  Sessions are keyed by the in-container path, so keep the workspace at
  `/workspaces/rockit` for `claude --resume` to find them.
- Gradle (`/root/.gradle`) and pub (`/root/.pub-cache`) caches live on named
  volumes.

## Building the app

```sh
flutter build apk --debug     # debug keystore, works out of the box
```

`flutter build apk --release` needs signing material that is not in the repo:
either `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`,
`keyPassword`) or the `X_KEYSTORE_PATH` environment variable, as configured in
`android/app/build.gradle`.
