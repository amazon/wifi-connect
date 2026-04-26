#!/usr/bin/env bash

set -euo pipefail

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

node <<'EOF_NODE'
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