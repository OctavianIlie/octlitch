#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ROOTFS="$PROJECT_ROOT/iso/work/rootfs"
ISO_TREE="$PROJECT_ROOT/iso/work/iso-tree"
BOOT_IMAGES="$PROJECT_ROOT/iso/work/boot-images"
OUTPUT_DIR="$PROJECT_ROOT/iso/output"

EROFS="$PROJECT_ROOT/iso/work/Octlitch-live.erofs"
OUTPUT_ISO="$OUTPUT_DIR/Octlitch-dev-x86_64.iso"

if [[ ! -d "$ROOTFS" ]]; then
    echo "Rootfs not found: $ROOTFS"
    exit 1
fi

if [[ ! -d "$ISO_TREE" ]]; then
    echo "ISO tree not found: $ISO_TREE"
    exit 1
fi

if [[ ! -f "$BOOT_IMAGES/eltorito_img2_uefi.img" ]]; then
    echo "UEFI boot image not found."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "==> Building LZMA EROFS"

sudo rm -f "$EROFS"

sudo mkfs.erofs \
    -zlzma \
    "$EROFS" \
    "$ROOTFS"

echo "==> Installing live filesystem"

sudo cp \
    "$EROFS" \
    "$ISO_TREE/LiveOS/squashfs.img"

sudo chown "$USER":"$USER" \
    "$ISO_TREE/LiveOS/squashfs.img"

echo "==> Restoring UEFI boot image"

cp \
    "$BOOT_IMAGES/eltorito_img2_uefi.img" \
    "$ISO_TREE/EFI/efiboot.img"

echo "==> Building hybrid ISO"

rm -f "$OUTPUT_ISO"

xorriso \
    -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "Fedora-KDE-Live-44" \
    -eltorito-boot boot/x86_64/loader/eltorito.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
    -eltorito-alt-boot \
    -e EFI/efiboot.img \
        -no-emul-boot \
    -isohybrid-gpt-basdat \
    -output "$OUTPUT_ISO" \
    "$ISO_TREE"

echo "==> Embedding media checksum"

implantisomd5 --force "$OUTPUT_ISO"

echo "==> Verifying media checksum"

checkisomd5 "$OUTPUT_ISO"

echo "==> Generating SHA256"

sha256sum "$OUTPUT_ISO" \
    > "$OUTPUT_ISO.sha256"

echo
echo "Build complete:"
ls -lh "$OUTPUT_ISO" "$OUTPUT_ISO.sha256"
