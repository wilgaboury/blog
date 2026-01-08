#!/bin/bash

set -euo pipefail
cd "$(dirname "$0")"

if ! command -v inotifywait &> /dev/null; then
    echo "ERROR: inotifywait is not installed"
    exit 1
fi

./generate.sh

inotifywait -m -r -e modify ./src | while read; do ./generate.sh; done