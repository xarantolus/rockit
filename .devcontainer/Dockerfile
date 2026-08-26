# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG FLUTTER_VERSION=3.47.1
ARG ANDROID_CMDLINE_TOOLS=16111833
# android-37.0 is required by current plugins (e.g. permission_handler_android).
# Platforms now carry a minor version; "android-37" alone does not exist.
ARG ANDROID_PLATFORMS="platforms;android-37.0 platforms;android-36 platforms;android-34"
ARG ANDROID_BUILD_TOOLS="build-tools;37.0.0 build-tools;36.0.0 build-tools;34.0.0"

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

RUN yes | sdkmanager --licenses > /dev/null \
    && sdkmanager --install "platform-tools" ${ANDROID_PLATFORMS} ${ANDROID_BUILD_TOOLS} > /dev/null

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

ENV CLAUDE_CONFIG_DIR=/root/.claude
ENV GRADLE_USER_HOME=/root/.gradle
ENV PUB_CACHE=/root/.pub-cache

WORKDIR /workspaces
CMD ["/bin/bash"]
