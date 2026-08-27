# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG FLUTTER_VERSION=3.47.1
ARG ANDROID_CMDLINE_TOOLS=16111833
# android-37.0 is required by current plugins (e.g. permission_handler_android).
# Platforms now carry a minor version; "android-37" alone does not exist.
ARG ANDROID_PLATFORMS="platforms;android-37.0 platforms;android-36 platforms;android-34"
ARG ANDROID_BUILD_TOOLS="build-tools;37.0.0 build-tools;36.0.0 build-tools;34.0.0"
# Two NDKs are genuinely needed:
#  - 28.2.13676358 matches flutter.ndkVersion for FLUTTER_VERSION (see
#    packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt), which
#    is where android/app/build.gradle gets its NDK version from.
#  - 25.1.8937393 is hardcoded by rive_common (a dependency of the pinned
#    rive ^0.13.20) in its ndkVersionFromLocalProperties(). It builds native
#    code with minSdk 19, which NDK 28 no longer supports, so it cannot simply
#    be pointed at the newer one via the rive.ndk.version property.
ARG ANDROID_NDK="ndk;28.2.13676358 ndk;25.1.8937393"
# rive_common builds native code with CMake, which Gradle otherwise downloads
# on the first build.
ARG ANDROID_CMAKE="cmake;3.22.1"
ARG ANDROID_SYSTEM_IMAGE="system-images;android-36;google_apis;x86_64"
ARG AVD_NAME=rockit

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Keep apt's debs so the cache mounts below stay useful.
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        openjdk-17-jdk-headless \
        git curl wget unzip zip xz-utils ca-certificates file \
        libglu1-mesa openssh-client less procps nano

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk

# sdkmanager only looks in cmdline-tools/latest.
RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && curl -fsSL -o /tmp/cmdline-tools.zip \
        "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
    && unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools" \
    && mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm -f /tmp/cmdline-tools.zip

ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# The NDK ships in the image on purpose. Left out, Gradle downloads it during
# the first build; if that download is interrupted (a timeout, a killed build)
# it leaves a partial NDK behind, and every later build fails with "Android
# sdkmanager did not install NDK <version>" until the directory is deleted by
# hand.
RUN yes | sdkmanager --licenses > /dev/null \
    && sdkmanager --install "platform-tools" ${ANDROID_PLATFORMS} ${ANDROID_BUILD_TOOLS} ${ANDROID_NDK} ${ANDROID_CMAKE} > /dev/null

ENV FLUTTER_ROOT=/opt/flutter
RUN curl -fsSL -o /tmp/flutter.tar.xz \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm -f /tmp/flutter.tar.xz

ENV PATH=${PATH}:${FLUTTER_ROOT}/bin:${FLUTTER_ROOT}/bin/cache/dart-sdk/bin:/root/.pub-cache/bin
# The workspace is bind-mounted and host-owned, but we run as root.
RUN git config --global --add safe.directory '*' \
    && flutter config --no-analytics --android-sdk "${ANDROID_HOME}" \
    && dart --disable-analytics || true
# Warm the Android artifacts so the first build in a fresh container is fast.
RUN flutter precache --android --universal \
    && flutter doctor -v || true
RUN yes | flutter doctor --android-licenses > /dev/null 2>&1 || true

# Ubuntu's node is too old for the Claude CLI tooling.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && ln -sf /root/.local/bin/claude /usr/local/bin/claude

# developer.android.com docs MCP. Pinned: the npm package declares no repository,
# so the version is fixed rather than resolved at build time.
RUN npm install -g android-docs-mcp@1.0.1

# gh + jq for the CI watcher (.ci-watch/ci-watch.sh).
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh jq

# Headless emulator. Needs /dev/kvm passed into the container; see
# .devcontainer/emulator.sh.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get install -y --no-install-recommends \
        libpulse0 libnss3 libxcomposite1 libxcursor1 libxdamage1 libxi6 \
        libxtst6 libasound2t64 libgl1 libx11-xcb1 libxfixes3 libxrandr2 \
        libdrm2 libgbm1 xz-utils
RUN sdkmanager --install "emulator" "${ANDROID_SYSTEM_IMAGE}" > /dev/null \
    && echo no | avdmanager create avd -n "${AVD_NAME}" -k "${ANDROID_SYSTEM_IMAGE}" -d pixel_6 --force
ENV PATH=${PATH}:${ANDROID_HOME}/emulator

# Drives the emulator (tap, type, screenshot) over MCP. Pinned.
RUN npm install -g @mobilenext/mobile-mcp@1.0.2

# Container marker podman doesn't create. Flutter checks it to skip its
# "running as root" warning, which doesn't apply in a container.
RUN touch /.dockerenv

ENV CLAUDE_CONFIG_DIR=/root/.claude
ENV GRADLE_USER_HOME=/root/.gradle
ENV PUB_CACHE=/root/.pub-cache

WORKDIR /workspaces
CMD ["/bin/bash"]
