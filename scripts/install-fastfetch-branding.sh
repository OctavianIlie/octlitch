#!/bin/bash
set -euo pipefail

ROOTFS="${1:-iso/work/rootfs}"

if [[ ! -d "$ROOTFS" ]]; then
    echo "Rootfs not found: $ROOTFS"
    exit 1
fi

sudo dnf \
    --installroot="$ROOTFS" \
    --releasever=44 \
    install -y fastfetch

install -Dm644 \
    branding/fastfetch/ascii.txt \
    "$ROOTFS/usr/share/octlitch/ascii.txt"

install -Dm644 \
    branding/fastfetch/config.jsonc \
    "$ROOTFS/etc/fastfetch/config.jsonc"

echo "Octlitch Fastfetch branding installed."
