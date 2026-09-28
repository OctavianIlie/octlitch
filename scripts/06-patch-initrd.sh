#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ROOTFS="${1:-$PROJECT_ROOT/iso/work/rootfs}"
INITRD="${2:-$PROJECT_ROOT/iso/work/iso-tree/boot/x86_64/loader/initrd}"

WORK="$PROJECT_ROOT/iso/work/initrd-patch"
BACKUP="$PROJECT_ROOT/iso/work/initrd.fedora-backup"

SKIPCPIO="/usr/lib/dracut/skipcpio"

if [[ ! -d "$ROOTFS" ]]; then
    echo "Rootfs not found:"
    echo "  $ROOTFS"
    exit 1
fi

if [[ ! -f "$INITRD" ]]; then
    echo "Live initrd not found:"
    echo "  $INITRD"
    exit 1
fi

if [[ ! -x "$SKIPCPIO" ]]; then
    echo "dracut skipcpio helper not found:"
    echo "  $SKIPCPIO"
    exit 1
fi

if [[ ! -f "$ROOTFS/etc/plymouth/plymouthd.conf" ]]; then
    echo "Octlitch Plymouth configuration is missing."
    exit 1
fi

if [[ ! -d "$ROOTFS/usr/share/plymouth/themes/octlitch" ]]; then
    echo "Octlitch Plymouth theme is missing."
    exit 1
fi

echo "==> Preparing initrd workspace"

sudo rm -rf "$WORK"
mkdir -p "$WORK/main"

# Keep the pristine Fedora initrd outside the ISO filesystem.
if [[ ! -f "$BACKUP" ]]; then
    cp "$INITRD" "$BACKUP"
fi

# Never ship an accidental backup inside the ISO.
rm -f "$(dirname "$INITRD")/initrd.fedora-backup"

SOURCE_INITRD="$BACKUP"

echo "==> Splitting Fedora initrd"

/usr/lib/dracut/skipcpio \
    "$SOURCE_INITRD" \
    > "$WORK/main.zst"

MAIN_TYPE="$(file -b "$WORK/main.zst")"

if [[ "$MAIN_TYPE" != *"Zstandard compressed data"* ]]; then
    echo "Unexpected main initrd format:"
    echo "  $MAIN_TYPE"
    exit 1
fi

TOTAL_SIZE="$(stat -c '%s' "$SOURCE_INITRD")"
MAIN_SIZE="$(stat -c '%s' "$WORK/main.zst")"
EARLY_SIZE="$((TOTAL_SIZE - MAIN_SIZE))"

if (( EARLY_SIZE <= 0 )); then
    echo "Could not determine early cpio size."
    exit 1
fi

echo "    Complete initrd: $TOTAL_SIZE bytes"
echo "    Early cpio:      $EARLY_SIZE bytes"
echo "    Main section:    $MAIN_SIZE bytes"

head -c "$EARLY_SIZE" \
    "$SOURCE_INITRD" \
    > "$WORK/early.cpio"

echo "==> Decompressing main initramfs"

zstd -d -f \
    "$WORK/main.zst" \
    -o "$WORK/main.cpio"

echo "==> Extracting main initramfs"

(
    cd "$WORK/main"
    sudo cpio -idmu --quiet < "$WORK/main.cpio"
)

echo "==> Installing Octlitch Plymouth configuration"

sudo install -Dm644 \
    "$ROOTFS/etc/plymouth/plymouthd.conf" \
    "$WORK/main/etc/plymouth/plymouthd.conf"

sudo rm -rf \
    "$WORK/main/usr/share/plymouth/themes/octlitch"

sudo mkdir -p \
    "$WORK/main/usr/share/plymouth/themes/octlitch"

sudo cp -a \
    "$ROOTFS/usr/share/plymouth/themes/octlitch/." \
    "$WORK/main/usr/share/plymouth/themes/octlitch/"

echo "==> Repacking main initramfs"

(
    cd "$WORK/main"

    sudo find . -print0 \
        | sudo cpio \
            --null \
            --quiet \
            -o \
            --format=newc \
        > "$WORK/main-patched.cpio"
)

echo "==> Compressing patched initramfs"

zstd -19 -f \
    "$WORK/main-patched.cpio" \
    -o "$WORK/main-patched.zst"

echo "==> Reassembling live initrd"

cat \
    "$WORK/early.cpio" \
    "$WORK/main-patched.zst" \
    > "$WORK/initrd"

install -m644 \
    "$WORK/initrd" \
    "$INITRD"

echo "==> Verifying Octlitch Plymouth configuration"

PLYMOUTH_CONFIG="$(
    lsinitrd -f etc/plymouth/plymouthd.conf "$INITRD"
)"

if ! grep -q '^Theme=octlitch$' <<< "$PLYMOUTH_CONFIG"; then
    echo "Plymouth theme verification failed."
    exit 1
fi

INITRD_LIST="$(lsinitrd "$INITRD")"

if ! grep -Fq \
    'usr/share/plymouth/themes/octlitch/octlitch.plymouth' \
    <<< "$INITRD_LIST"
then
    echo "Octlitch Plymouth theme is missing from rebuilt initrd."
    exit 1
fi

echo
echo "Live initrd patched successfully."
echo
echo "Original Fedora initrd backup:"
echo "  $BACKUP"
