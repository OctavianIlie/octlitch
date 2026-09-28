#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ISO="$PROJECT_ROOT/iso/input/Fedora-KDE-Desktop-Live-44-1.7.x86_64.iso"
WORK="$PROJECT_ROOT/iso/work"
ISO_TREE="$WORK/iso-tree"
ROOTFS="$WORK/rootfs"
MNT_ROOT="$WORK/mnt-root"
BOOT_IMAGES="$WORK/boot-images"

EXPECTED_SHA256="c8295961d4c41adbf785a31a17c21a971d3b7415fda72dcad0c11c49577bf03a"

if [[ ! -f "$ISO" ]]; then
    echo "Base ISO not found:"
    echo "  $ISO"
    exit 1
fi

echo "==> Verifying Fedora ISO"

ACTUAL_SHA256="$(sha256sum "$ISO" | awk '{print $1}')"

if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
    echo "ERROR: Fedora ISO checksum mismatch."
    echo "Expected: $EXPECTED_SHA256"
    echo "Actual:   $ACTUAL_SHA256"
    exit 1
fi

echo "Checksum OK."

echo "==> Preparing build workspace"

sudo umount "$MNT_ROOT" 2>/dev/null || true

rm -rf \
    "$ISO_TREE" \
    "$ROOTFS" \
    "$BOOT_IMAGES"

mkdir -p \
    "$ISO_TREE" \
    "$ROOTFS" \
    "$MNT_ROOT" \
    "$BOOT_IMAGES"

echo "==> Extracting ISO filesystem"

xorriso \
    -osirrox on \
    -indev "$ISO" \
    -extract / "$ISO_TREE"

echo "==> Extracting original boot images"

xorriso \
    -indev "$ISO" \
    -osirrox on \
    -extract_boot_images "$BOOT_IMAGES"

echo "==> Mounting Fedora live root filesystem"

sudo mount \
    -o loop,ro \
    "$ISO_TREE/LiveOS/squashfs.img" \
    "$MNT_ROOT"

cleanup() {
    sudo umount "$MNT_ROOT" 2>/dev/null || true
}

trap cleanup EXIT

echo "==> Copying root filesystem"

sudo cp -aHAX \
    "$MNT_ROOT/." \
    "$ROOTFS/"

sudo chown root:root "$ROOTFS"

cleanup
trap - EXIT

echo
echo "Base extraction complete."
echo
echo "ISO tree:"
echo "  $ISO_TREE"
echo
echo "Root filesystem:"
echo "  $ROOTFS"
echo
echo "Boot images:"
echo "  $BOOT_IMAGES"
