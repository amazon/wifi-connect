#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

default_targets=(
	aarch64-unknown-linux-gnu
	armv7-unknown-linux-gnueabihf
	x86_64-unknown-linux-gnu
	i686-unknown-linux-gnu
)

include_ui=false
targets=()

usage() {
	cat <<'EOF'
usage: scripts/local-build.sh [--ui] [target-triple ...]

Build release tarballs with cross-rs. When no targets are provided, the default
release matrix is used.

Options:
	--ui    Also build ui/wifi-connect-ui.tar.gz locally.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--ui)
			include_ui=true
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			targets+=("$1")
			;;
	esac
	shift
done

if [[ ${#targets[@]} -eq 0 ]]; then
	targets=("${default_targets[@]}")
fi

if ! command -v cross >/dev/null 2>&1; then
	echo "cross is required but was not found in PATH" >&2
	exit 1
fi

for target in "${targets[@]}"; do
	bash "${script_dir}/build-rust-release-asset.sh" "${target}"
done

if [[ "${include_ui}" == true ]]; then
	pushd "${script_dir}/../ui" >/dev/null
	if [[ -e package-lock.json ]]; then
		npm ci
	else
		npm i
	fi
	npm run build
	tar --auto-compress -cvf wifi-connect-ui.tar.gz -C build .
	popd >/dev/null
fi
