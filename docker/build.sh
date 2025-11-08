#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build.sh [TARGET]

Build wifi-connect for the given Rust target triple. If TARGET is omitted,
`x86_64-unknown-linux-gnu` is used. The resulting artifacts are placed under
`/workspace/target/<triple>/release`.
EOF
}

TARGET=${1:-x86_64-unknown-linux-gnu}

ensure_rust_target() {
    local triple="$1"
    if ! rustup target list --installed | grep -Fxq "${triple}"; then
        rustup target add "${triple}"
    fi
}

case "${TARGET}" in
    x86_64-unknown-linux-gnu)
        export CC_x86_64_unknown_linux_gnu=gcc
        export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=gcc
        ;;
    aarch64-unknown-linux-gnu)
        ensure_rust_target "${TARGET}"
        export CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc
        export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
        ;;
    armv7-unknown-linux-gnueabihf)
        ensure_rust_target "${TARGET}"
        export CC_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-gcc
        export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc
        ;;
    *)
        echo "Unsupported target: ${TARGET}" >&2
        usage
        exit 1
        ;;
	esac

BUILD_ROOT="/tmp/wifi-connect-build"
WORKSPACE="/workspace"

rm -rf "${BUILD_ROOT}"
mkdir -p "${BUILD_ROOT}"
rsync -a --delete --exclude target --exclude .git "${WORKSPACE}/" "${BUILD_ROOT}/"

cd "${BUILD_ROOT}"
rm -f Cargo.lock
export CARGO_TARGET_DIR="${WORKSPACE}/target"

cargo fetch
rustc --version
cargo build --release --target "${TARGET}"

if command -v strip >/dev/null 2>&1; then
    case "${TARGET}" in
        x86_64-unknown-linux-gnu)
            strip --strip-unneeded "${WORKSPACE}/target/${TARGET}/release/wifi-connect" || true
            ;;
        aarch64-unknown-linux-gnu)
            aarch64-linux-gnu-strip --strip-unneeded "${WORKSPACE}/target/${TARGET}/release/wifi-connect" || true
            ;;
        armv7-unknown-linux-gnueabihf)
            arm-linux-gnueabihf-strip --strip-unneeded "${WORKSPACE}/target/${TARGET}/release/wifi-connect" || true
            ;;
    esac
fi


# When CARGO_TARGET_DIR points to the workspace the artifacts are already there,
# so there is nothing left to synchronise from the temporary directory.
