#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${1:-$PROJECT_ROOT/iso/work/rootfs}"

LIBREWOLF_REPO="$PROJECT_ROOT/packages/librewolf/librewolf.repo"
LIBREWOLF_KEY="$PROJECT_ROOT/packages/librewolf/pubkey.gpg"
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

if [[ ! -f "$LIBREWOLF_KEY" ]]; then
    echo "LibreWolf signing key missing:"
    echo "  $LIBREWOLF_KEY"
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

echo "==> Installing LibreWolf signing key"

sudo install -Dm644 \
    "$LIBREWOLF_KEY" \
    "$ROOTFS/etc/pki/rpm-gpg/RPM-GPG-KEY-librewolf"

sudo rpm \
    --root "$ROOTFS" \
    --import \
    "$ROOTFS/etc/pki/rpm-gpg/RPM-GPG-KEY-librewolf"
echo "==> Installing LibreWolf repository configuration"

sudo install -Dm644 \
    "$LIBREWOLF_REPO" \
    "$ROOTFS/etc/yum.repos.d/librewolf.repo"

echo "==> Installing LibreWolf"

if sudo dnf \
    --installroot="$ROOTFS" \
    --releasever=44 \
    repoquery --repo=librewolf librewolf \
    | grep -q '^librewolf'; then

    sudo dnf \
        --installroot="$ROOTFS" \
        --releasever=44 \
        install -y librewolf

else
    echo "LibreWolf repository metadata does not expose the package."
    echo "Falling back to the newest official signed x86_64 RPM."

    LIBREWOLF_POOL="https://repo.librewolf.net/pool/"
    LIBREWOLF_RPM="/tmp/librewolf.rpm"

    LIBREWOLF_RPM_NAME="$(
        curl -fsSL "$LIBREWOLF_POOL" \
        | grep -oE 'librewolf-[0-9][^"]*-linux-x86_64-rpm\.rpm' \
        | sort -V \
        | tail -n1
    )"

    if [[ -z "$LIBREWOLF_RPM_NAME" ]]; then
        echo "Could not discover a LibreWolf x86_64 RPM."
        exit 1
    fi

    echo "==> Downloading $LIBREWOLF_RPM_NAME"

    curl -fL \
        "${LIBREWOLF_POOL}${LIBREWOLF_RPM_NAME}" \
        -o "$LIBREWOLF_RPM"

    sudo dnf \
        --installroot="$ROOTFS" \
        --releasever=44 \
        install -y "$LIBREWOLF_RPM"

    rm -f "$LIBREWOLF_RPM"
fi

echo "==> Installing Octlitch installer browser wrapper"

sudo install -Dm755 \
    "$PROJECT_ROOT/system/usr/local/bin/octlitch-installer-browser" \
    "$ROOTFS/usr/local/bin/octlitch-installer-browser"

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

echo
echo "Application installation complete."
