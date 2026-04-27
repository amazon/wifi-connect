#!/usr/bin/env bash

set -euo pipefail

current_version() {
  awk -F '"' '/^version = "/ { print $2; exit }' Cargo.toml
}

if ! command -v node >/dev/null 2>&1; then
  echo "node is required but was not found in PATH" >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required but was not found in PATH" >&2
  exit 1
fi

export NODE_PATH="${NODE_PATH:-$(npm root --quiet -g)}"

if [[ ! -f .versionbot/CHANGELOG.yml ]]; then
  "${NODE_PATH}/versionist/scripts/generate-changelog.sh" .
fi

stdout_file="$(mktemp)"
stderr_file="$(mktemp)"

cleanup() {
  rm -f "$stdout_file" "$stderr_file"
}

trap cleanup EXIT

if node >"$stdout_file" 2>"$stderr_file" <<'EOF_NODE'
const { runBalenaVersionist } = require('balena-versionist');

(async () => {
  const version = await runBalenaVersionist(process.cwd(), {
    silent: false,
  });

  if (!version) {
    throw new Error('balena-versionist did not produce a version');
  }

  process.stdout.write(`${version}\n`);
})().catch((error) => {
  console.error(error.stack || error.message);
  process.exit(1);
});
EOF_NODE
then
  cat "$stderr_file" >&2
  cat "$stdout_file"
elif grep -q 'No commits were annotated with a change type since version' "$stderr_file"; then
  cat "$stderr_file" >&2
  current_version
else
  cat "$stderr_file" >&2
  exit 1
fi