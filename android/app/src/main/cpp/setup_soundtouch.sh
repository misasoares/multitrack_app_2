#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TARGET_DIR="$DIR/soundtouch"

echo "Setting up SoundTouch in $TARGET_DIR..."

# Create temp dir
TEMP_DIR=$(mktemp -d)

# Clone SoundTouch from Codeberg (Official Repo)
echo "Cloning SoundTouch from Codeberg..."
git clone https://codeberg.org/soundtouch/soundtouch.git "$TEMP_DIR/soundtouch-repo"

echo "Checking structure..."
ls -F "$TEMP_DIR/soundtouch-repo"

# Move vital source files to target
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

SOURCE_ROOT="$TEMP_DIR/soundtouch-repo"

if [ ! -d "$SOURCE_ROOT/include" ]; then
    echo "Error: include directory not found in $SOURCE_ROOT"
    ls -R "$SOURCE_ROOT"
    exit 1
fi

echo "Copying headers and sources..."
# Copy include folder
cp -r "$SOURCE_ROOT/include" "$TARGET_DIR/"

# Copy source/SoundTouch folder to target/source
mkdir -p "$TARGET_DIR/source"
cp -r "$SOURCE_ROOT/source/SoundTouch/"* "$TARGET_DIR/source/"

# Cleanup
rm -rf "$TEMP_DIR"

echo "SoundTouch setup complete."
ls -R "$TARGET_DIR"
