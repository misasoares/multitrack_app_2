#!/bin/bash
set -e
TEMP_DIR=$(mktemp -d)
git clone https://gitlab.com/soundtouch/soundtouch.git "$TEMP_DIR/soundtouch-repo"
cat "$TEMP_DIR/soundtouch-repo/readme.md"
rm -rf "$TEMP_DIR"
