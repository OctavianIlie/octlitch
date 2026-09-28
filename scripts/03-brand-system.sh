#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${1:-$PROJECT_ROOT/iso/work/rootfs}"
ISO_TREE="${2:-$PROJECT_ROOT/iso/work/iso-tree}"
LOGO="$PROJECT_ROOT/artwork/octlitch-logo.png"

if [[ ! -d "$ROOTFS" ]]; then
    echo "Rootfs not found: $ROOTFS"
    exit 1
fi

if [[ ! -d "$ISO_TREE" ]]; then
    echo "ISO tree not found: $ISO_TREE"
    exit 1
fi

if [[ ! -f "$LOGO" ]]; then
    echo "Octlitch logo not found: $LOGO"
    exit 1
fi

echo "==> Writing Octlitch OS identity"

sudo tee "$ROOTFS/etc/os-release" >/dev/null <<'OSRELEASE'
NAME="Octlitch Linux"
VERSION="1.0 Development"
RELEASE_TYPE=development
ID=octlitch
ID_LIKE=fedora
VERSION_ID=1
PRETTY_NAME="Octlitch Linux 1.0 Development"
ANSI_COLOR="0;38;2;120;80;220"
LOGO=octlitch-logo
DEFAULT_HOSTNAME=octlitch
VARIANT="KDE Plasma"
VARIANT_ID=kde
OSRELEASE

echo "octlitch" | sudo tee "$ROOTFS/etc/hostname" >/dev/null

echo "==> Installing Octlitch application icon"

sudo mkdir -p \
    "$ROOTFS/usr/share/icons/hicolor/512x512/apps"

magick \
    "$LOGO" \
    -resize 512x512 \
    /tmp/octlitch-logo-512.png

sudo install -m644 \
    /tmp/octlitch-logo-512.png \
    "$ROOTFS/usr/share/icons/hicolor/512x512/apps/octlitch-logo.png"

rm -f /tmp/octlitch-logo-512.png

echo "==> Branding installer launcher"

LIVEINST="$ROOTFS/usr/share/applications/liveinst.desktop"

if [[ -f "$LIVEINST" ]]; then
    sudo sed -i \
        's/^Icon=.*/Icon=octlitch-logo/' \
        "$LIVEINST"
fi

echo "==> Branding KDE Welcome Center"

WELCOME="$ROOTFS/usr/share/applications/org.kde.plasma-welcome.desktop"

if [[ -f "$WELCOME" ]]; then
    sudo sed -i \
        -e 's/^Comment=.*/Comment=Welcome to Octlitch Linux/' \
        -e 's/^GenericName=.*/GenericName=Octlitch Welcome Center/' \
        -e 's/^Icon=.*/Icon=octlitch-logo/' \
        -e 's/^Name=.*/Name=Octlitch Welcome Center/' \
        "$WELCOME"
fi

echo "==> Creating Octlitch Plymouth theme"

PLYMOUTH_BASE="$ROOTFS/usr/share/plymouth/themes/spinner"
PLYMOUTH_THEME="$ROOTFS/usr/share/plymouth/themes/octlitch"

if [[ ! -d "$PLYMOUTH_BASE" ]]; then
    echo "Spinner Plymouth theme not found: $PLYMOUTH_BASE"
    exit 1
fi

sudo rm -rf "$PLYMOUTH_THEME"
sudo cp -a "$PLYMOUTH_BASE" "$PLYMOUTH_THEME"

magick \
    "$LOGO" \
    -resize 128x128 \
    /tmp/octlitch-plymouth-watermark.png

sudo install -m644 \
    /tmp/octlitch-plymouth-watermark.png \
    "$PLYMOUTH_THEME/watermark.png"

rm -f /tmp/octlitch-plymouth-watermark.png

sudo rm -f "$PLYMOUTH_THEME/spinner.plymouth"

sudo tee "$PLYMOUTH_THEME/octlitch.plymouth" >/dev/null <<'PLYMOUTH'
[Plymouth Theme]
Name=Octlitch
Description=Octlitch Linux boot splash
ModuleName=two-step

[two-step]
Font=Cantarell 12
TitleFont=Cantarell Light 30
ImageDir=/usr/share/plymouth/themes/octlitch
DialogHorizontalAlignment=.5
DialogVerticalAlignment=.382
TitleHorizontalAlignment=.5
TitleVerticalAlignment=.382
HorizontalAlignment=.5
VerticalAlignment=.62
WatermarkHorizontalAlignment=.5
WatermarkVerticalAlignment=.40
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x000000
BackgroundEndColor=0x000000
ProgressBarBackgroundColor=0x606060
ProgressBarForegroundColor=0xffffff
MessageBelowAnimation=true

[boot-up]
UseEndAnimation=false

[shutdown]
UseEndAnimation=false

[reboot]
UseEndAnimation=false

[updates]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Installing Updates...
SubTitle=Do not turn off your computer

[system-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading System...
SubTitle=Do not turn off your computer

[firmware-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading Firmware...
SubTitle=Do not turn off your computer

[system-reset]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Resetting System...
SubTitle=Do not turn off your computer
PLYMOUTH

sudo mkdir -p "$ROOTFS/etc/plymouth"

sudo tee "$ROOTFS/etc/plymouth/plymouthd.conf" >/dev/null <<'PLYMOUTHCONF'
[Daemon]
Theme=octlitch
ShowDelay=0
DeviceTimeout=8
PLYMOUTHCONF

echo "==> Branding live boot menu"

GRUB_CFG="$ISO_TREE/boot/grub2/grub.cfg"

if [[ -f "$GRUB_CFG" ]]; then
    sudo sed -i \
        -e 's/Start Fedora-KDE-Live 44/Start Octlitch and install Octlitch/g' \
        -e 's/Test this media & start Fedora-KDE-Live 44/Test this media \& start Octlitch/g' \
        -e 's/Start Fedora-KDE-Live 44 in basic graphics mode/Start Octlitch in basic graphics mode/g' \
        "$GRUB_CFG"
fi

echo
echo "System branding complete."
echo
echo "NOTE:"
echo "  Plymouth is installed in the rootfs, but the live initrd"
echo "  still needs to be patched by the later initrd stage."
echo
echo "  The ISO volume ID remains Fedora-KDE-Live-44 intentionally."
