#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <tag-or-version>" >&2
  exit 1
fi

requested_tag="$1"
requested_tag="${requested_tag#refs/tags/}"

if [[ "${requested_tag}" != v* ]]; then
  requested_tag="v${requested_tag}"
fi

awk -v requested_tag="${requested_tag}" '
  $0 == "# " requested_tag {
    capture = 1
  }
  capture && /^# v/ && $0 != "# " requested_tag {
    exit
  }
  capture {
    print
  }
' CHANGELOG.md