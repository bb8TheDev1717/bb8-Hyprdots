#!/bin/bash
# Wrapper fuer aur-malware-check (https://github.com/lenucksi/aur-malware-check)
# Tool liegt in ~/Dokumente/tools/aur-malware-check

set -euo pipefail

TOOL_DIR="$HOME/Dokumente/tools/aur-malware-check"

if [[ ! -d "$TOOL_DIR" ]]; then
    echo "Fehler: $TOOL_DIR nicht gefunden." >&2
    exit 1
fi

cd "$TOOL_DIR"
python3 -m aur_check --full "$@"
