#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${1:-$PROJECT_ROOT/iso/work/rootfs}"

if [[ ! -d "$ROOTFS" ]]; then
    echo "Rootfs not found: $ROOTFS"
    exit 1
fi

copy_file() {
    local src="$1"
    local dst="$2"

    if [[ ! -f "$src" ]]; then
        echo "Missing file: $src"
        exit 1
    fi

    sudo install -Dm644 "$src" "$dst"
}

copy_exec() {
    local src="$1"
    local dst="$2"

    if [[ ! -f "$src" ]]; then
        echo "Missing executable: $src"
        exit 1
    fi

    sudo install -Dm755 "$src" "$dst"
}

copy_dir() {
    local src="$1"
    local dst="$2"

    if [[ ! -d "$src" ]]; then
        echo "Missing directory: $src"
        exit 1
    fi

    sudo rm -rf "$dst"
    sudo mkdir -p "$(dirname "$dst")"
    sudo cp -a "$src" "$dst"
}

echo "==> Installing KDE configuration"

copy_file \
    "$PROJECT_ROOT/plasma/config/kdeglobals" \
    "$ROOTFS/etc/xdg/kdeglobals"

copy_file \
    "$PROJECT_ROOT/plasma/config/krunnerrc" \
    "$ROOTFS/etc/xdg/krunnerrc"

copy_file \
    "$PROJECT_ROOT/plasma/config/kwinrc" \
    "$ROOTFS/etc/xdg/kwinrc"

copy_file \
    "$PROJECT_ROOT/plasma/config/breezerc" \
    "$ROOTFS/etc/xdg/breezerc"

copy_file \
    "$PROJECT_ROOT/plasma/config/kscreenlockerrc" \
    "$ROOTFS/etc/xdg/kscreenlockerrc"

copy_file \
    "$PROJECT_ROOT/plasma/config/kscreenlockerrc" \
    "$ROOTFS/etc/xdg/kscreenlockerrc"

echo "==> Installing Octlitch color schemes"

sudo mkdir -p "$ROOTFS/usr/share/color-schemes"

for scheme in \
    OctlitchValley \
    OctlitchModel \
    OctlitchCoast \
    OctlitchMountain
do
    copy_file \
        "$PROJECT_ROOT/plasma/color-schemes/${scheme}.colors" \
        "$ROOTFS/usr/share/color-schemes/${scheme}.colors"
done

echo "==> Installing wallpapers"

sudo rm -rf "$ROOTFS/usr/share/wallpapers/Octlitch"
sudo mkdir -p "$ROOTFS/usr/share/wallpapers/Octlitch"

for wallpaper in \
    artificial-valley.jpg \
    3d-model.jpg \
    beach-path.jpg \
    Mountain.jpg
do
    copy_file \
        "$PROJECT_ROOT/artwork/wallpapers/$wallpaper" \
        "$ROOTFS/usr/share/wallpapers/Octlitch/$wallpaper"
done

echo "==> Installing Octlitch Sharp decoration"

copy_dir \
    "$PROJECT_ROOT/plasma/kwin/org.octlitch.sharp" \
    "$ROOTFS/usr/share/kwin/decorations/org.octlitch.sharp"

echo "==> Installing Octlitch global themes"

for theme in \
    valley \
    model \
    coast \
    mountain
do
    copy_dir \
        "$PROJECT_ROOT/plasma/look-and-feel/org.octlitch.${theme}.desktop" \
        "$ROOTFS/usr/share/plasma/look-and-feel/org.octlitch.${theme}.desktop"
done

# Remove the old generic runtime theme if it still exists.
sudo rm -rf \
    "$ROOTFS/usr/share/plasma/look-and-feel/org.octlitch.desktop"

echo "==> Installing first-login setup"

copy_exec \
    "$PROJECT_ROOT/plasma/bin/octlitch-first-login" \
    "$ROOTFS/usr/local/bin/octlitch-first-login"

copy_file \
    "$PROJECT_ROOT/plasma/autostart/octlitch-first-login.desktop" \
    "$ROOTFS/etc/xdg/autostart/octlitch-first-login.desktop"

echo "==> Setting compact default Plasma panel"

LAYOUT="$ROOTFS/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js"

if [[ -f "$LAYOUT" ]]; then
    if grep -q 'panel.height' "$LAYOUT"; then
        sudo sed -i \
            's/panel\.height[[:space:]]*=.*/panel.height = 32/' \
            "$LAYOUT"
    else
        echo 'panel.height = 32' | sudo tee -a "$LAYOUT" >/dev/null
    fi
else
    echo "Default Plasma panel layout not found: $LAYOUT"
    exit 1
fi

echo "==> Refreshing icon cache"

if [[ -x "$ROOTFS/usr/bin/gtk-update-icon-cache" ]]; then
    sudo chroot "$ROOTFS" \
        gtk-update-icon-cache -f \
        /usr/share/icons/hicolor \
        >/dev/null 2>&1 || true
fi


echo
echo "Octlitch Plasma rice installed."
echo
echo "Default global theme:"
grep -E '^LookAndFeelPackage=' \
    "$ROOTFS/etc/xdg/kdeglobals" \
    || true
