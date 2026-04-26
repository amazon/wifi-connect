#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 <target-triple> [package-name]" >&2
  exit 1
fi

target="$1"
package_name="${2:-$(sed -n 's/^name = "\(.*\)"$/\1/p' Cargo.toml | head -n 1)}"

if [[ -z "${package_name}" ]]; then
  echo "failed to determine package name from Cargo.toml" >&2
  exit 1
fi

if ! command -v cross >/dev/null 2>&1; then
  echo "cross is required but was not found in PATH" >&2
  exit 1
fi

cross build --locked --release --target "${target}"

binary_path="target/${target}/release/${package_name}"
archive_name="${package_name}-${target}.tar.gz"

if [[ ! -f "${binary_path}" ]]; then
  echo "expected release binary ${binary_path} was not produced" >&2
  exit 1
fi

if command -v llvm-strip >/dev/null 2>&1; then
  llvm-strip "${binary_path}"
elif command -v strip >/dev/null 2>&1; then
  strip "${binary_path}" || true
fi

tar --auto-compress -cvf "${archive_name}" -C "$(dirname "${binary_path}")" "$(basename "${binary_path}")"
printf '%s\n' "${archive_name}"