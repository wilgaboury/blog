#!/bin/bash

set -euo pipefail
cd "$(dirname "$0")"

PUB=./public
SRC=./src

rm -rf $PUB

if ! command -v pandoc &> /dev/null; then
    echo "ERROR: pandoc is not installed"
    exit 1
fi

mapfile -t FILES < <(find "$SRC" -type f)
for FILE in "${FILES[@]}"; do
    REL="${FILE#$SRC/}"
    DEST="$PUB/$REL"
    mkdir -p "$(dirname "$DEST")"

    case $REL in
        *.md)
            sed 's/\.md)/.html)/g' $FILE | pandoc -o ${DEST%.md}.html
            ;;
        *)
            cp $FILE $DEST
            ;;
    esac
done