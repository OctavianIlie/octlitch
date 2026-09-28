#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${1:-$PROJECT_ROOT/iso/work/rootfs}"

LIBREWOLF_REPO="$PROJECT_ROOT/packages/librewolf/librewolf.repo"
LIVE_SESSION="$PROJECT_ROOT/plasma/livesys/livesys-kde"
NVIDIA_HELPER="$PROJECT_ROOT/system/usr/local/sbin/octlitch-install-nvidia"

if [[ ! -d "$ROOTFS" ]]; then
    echo "Rootfs not found:"
    echo "  $ROOTFS"
    exit 1
fi

if [[ ! -f "$LIBREWOLF_REPO" ]]; then
    echo "LibreWolf repo definition missing:"
    echo "  $LIBREWOLF_REPO"
    exit 1
fi

if [[ ! -f "$LIVE_SESSION" ]]; then
    echo "Live session configuration missing:"
    echo "  $LIVE_SESSION"
    exit 1
fi

if [[ ! -f "$NVIDIA_HELPER" ]]; then
    echo "NVIDIA helper missing:"
    echo "  $NVIDIA_HELPER"
    exit 1
fi

echo "==> Installing LibreWolf repository configuration"

sudo install -Dm644 \
    "$LIBREWOLF_REPO" \
    "$ROOTFS/etc/yum.repos.d/librewolf.repo"

echo "==> Installing LibreWolf"

sudo dnf \
    --installroot="$ROOTFS" \
    --releasever=44 \
    --setopt=install_weak_deps=False \
    install -y librewolf

echo "==> Installing Fastfetch and Octlitch branding"

"$PROJECT_ROOT/scripts/install-fastfetch-branding.sh" "$ROOTFS"

echo "==> Installing Octlitch live-session configuration"

sudo install -Dm755 \
    "$LIVE_SESSION" \
    "$ROOTFS/usr/libexec/livesys/sessions.d/livesys-kde"

echo "==> Installing Octlitch NVIDIA helper"

sudo install -Dm755 \
    "$NVIDIA_HELPER" \
    "$ROOTFS/usr/local/sbin/octlitch-install-nvidia"

echo "==> Verifying installed applications"

sudo chroot "$ROOTFS" rpm -q \
    librewolf \
    fastfetch

if [[ ! -f "$ROOTFS/usr/share/applications/librewolf.desktop" ]]; then
    echo "LibreWolf desktop entry is missing."
    exit 1
fi

if [[ ! -f "$ROOTFS/usr/share/octlitch/ascii.txt" ]]; then
    echo "Octlitch Fastfetch logo is missing."
    exit 1
fi

if [[ ! -f "$ROOTFS/etc/fastfetch/config.jsonc" ]]; then
    echo "Octlitch Fastfetch configuration is missing."
    exit 1
fi

if [[ ! -x "$ROOTFS/usr/local/sbin/octlitch-install-nvidia" ]]; then
    echo "Octlitch NVIDIA helper is missing or not executable."
    exit 1
fi

echo "==> Cleaning package cache"

sudo dnf \
    --installroot="$ROOTFS" \
    --releasever=44 \
    clean all

sudo rm -rf \
    "$ROOTFS/var/cache/dnf" \
    "$ROOTFS/var/cache/libdnf5"

echo
echo "Application installation complete."
