# Builder image for wifi-connect binaries (supports cross compilation)
FROM rust:bullseye

RUN dpkg --add-architecture arm64 \
    && dpkg --add-architecture armhf \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        libdbus-1-dev \
        libdbus-1-dev:arm64 \
        libdbus-1-dev:armhf \
        libc6-dev:arm64 \
        libc6-dev:armhf \
        gcc-aarch64-linux-gnu \
        gcc-arm-linux-gnueabihf \
        binutils \
        binutils-aarch64-linux-gnu \
        binutils-arm-linux-gnueabihf \
        rsync \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

ENV PKG_CONFIG_ALLOW_CROSS=1 \
    PKG_CONFIG_PATH_aarch64_unknown_linux_gnu=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/local/lib/aarch64-linux-gnu/pkgconfig \
    PKG_CONFIG_PATH_armv7_unknown_linux_gnueabihf=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/local/lib/arm-linux-gnueabihf/pkgconfig

COPY docker/build.sh /usr/local/bin/build-wifi-connect

RUN chmod +x /usr/local/bin/build-wifi-connect

ENTRYPOINT ["/usr/local/bin/build-wifi-connect"]
