#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${1:-$PROJECT_ROOT/iso/work/rootfs}"

if [[ ! -d "$ROOTFS" ]]; then
    echo "Rootfs not found: $ROOTFS"
    exit 1
fi

DNF=(
    sudo dnf
    --installroot="$ROOTFS"
    --releasever=44
    --setopt=install_weak_deps=False
)

remove_if_present() {
    local requested=("$@")
    local installed=()

    for pkg in "${requested[@]}"; do
        if [[ "$pkg" == *'*'* ]]; then
            while IFS= read -r match; do
                [[ -n "$match" ]] && installed+=("$match")
            done < <(
                sudo chroot "$ROOTFS" rpm -qa \
                    | grep -E "^${pkg//\*/.*}($|-)" \
                    || true
            )
        else
            if sudo chroot "$ROOTFS" rpm -q "$pkg" >/dev/null 2>&1; then
                installed+=("$pkg")
            fi
        fi
    done

    if (( ${#installed[@]} == 0 )); then
        echo "    Nothing installed from this group."
        return 0
    fi

    "${DNF[@]}" remove -y "${installed[@]}"
}

echo "==> Removing browser and office suite"

remove_if_present \
    firefox \
    firefox-langpacks \
    'libreoffice*'

echo "==> Removing games"

remove_if_present \
    kpat \
    kmines \
    kmahjongg \
    libkmahjongg \
    libkmahjongg-data

echo "==> Removing optional KDE applications"

remove_if_present \
    neochat \
    kio-gdrive \
    plasma-welcome-fedora \
    plasma-workspace-wallpapers \
    plasma-welcome \
    plasma-setup

echo "==> Removing KDE PIM stack"

remove_if_present \
    'akonadi*' \
    'akregator*' \
    calendarsupport \
    eventviews \
    'grantlee-editor*' \
    incidenceeditor \
    'kaddressbook*' \
    'kdepim*' \
    'kmail*' \
    'kontact*' \
    'korganizer*' \
    'libksieve*' \
    'mailcommon*' \
    'mailimporter*' \
    'messagelib*' \
    'pimcommon*' \
    'pim-data-exporter*' \
    'pim-sieve-editor*'

echo "==> Removing Discover stack"

remove_if_present \
    plasma-discover \
    plasma-discover-notifier \
    plasma-discover-packagekit \
    plasma-discover-flatpak \
    plasma-discover-kns \
    plasma-discover-offline-updates

echo "==> Removing heavy/unused desktop components"

remove_if_present \
    qt6-qtwebengine \
    qt6-qtwebview \
    kaccounts-providers \
    kdeplasma-addons \
    khelpcenter \
    plasma-nm-openconnect \
    signon-ui \
    slitherer \
    kleopatra

echo "==> Removing container/server/Java stack"

remove_if_present \
    toolbox \
    podman \
    podman-sequoia \
    skopeo \
    containers-common \
    containers-common-extra \
    mariadb \
    mariadb-backup \
    mariadb-client-utils \
    mariadb-common \
    mariadb-connector-c \
    mariadb-connector-c-config \
    mariadb-cracklib-password-check \
    mariadb-errmsg \
    mariadb-gssapi-server \
    mariadb-server \
    mysql-selinux \
    qt6-qtbase-mysql \
    java-25-openjdk-crypto-adapter \
    java-25-openjdk-headless \
    javapackages-filesystem

echo "==> Synchronizing remaining Fedora packages"

"${DNF[@]}" \
    --refresh \
    distro-sync -y

echo "==> Verifying Plasma package alignment"

KWIN_VERSION="$(
    sudo chroot "$ROOTFS" \
        rpm -q --qf '%{VERSION}\n' kwin
)"

KSCREENLOCKER_VERSION="$(
    sudo chroot "$ROOTFS" \
        rpm -q --qf '%{VERSION}\n' kscreenlocker
)"

PLASMA_WORKSPACE_VERSION="$(
    sudo chroot "$ROOTFS" \
        rpm -q --qf '%{VERSION}\n' plasma-workspace
)"

PLASMA_LOGIN_VERSION="$(
    sudo chroot "$ROOTFS" \
        rpm -q --qf '%{VERSION}\n' plasma-login-manager
)"

echo "    KWin:                 $KWIN_VERSION"
echo "    KScreenLocker:        $KSCREENLOCKER_VERSION"
echo "    Plasma Workspace:     $PLASMA_WORKSPACE_VERSION"
echo "    Plasma Login Manager: $PLASMA_LOGIN_VERSION"

if [[ "$KWIN_VERSION" != "$KSCREENLOCKER_VERSION" ]]; then
    echo
    echo "ERROR: Plasma package mismatch detected."
    echo "KWin:          $KWIN_VERSION"
    echo "KScreenLocker: $KSCREENLOCKER_VERSION"
    echo
    echo "Refusing to continue with an inconsistent Plasma stack."
    exit 1
fi

if [[ "$KWIN_VERSION" != "$PLASMA_WORKSPACE_VERSION" ]]; then
    echo
    echo "ERROR: Plasma package mismatch detected."
    echo "KWin:             $KWIN_VERSION"
    echo "Plasma Workspace: $PLASMA_WORKSPACE_VERSION"
    echo
    echo "Refusing to continue with an inconsistent Plasma stack."
    exit 1
fi

if [[ "$KWIN_VERSION" != "$PLASMA_LOGIN_VERSION" ]]; then
    echo
    echo "ERROR: Plasma package mismatch detected."
    echo "KWin:                 $KWIN_VERSION"
    echo "Plasma Login Manager: $PLASMA_LOGIN_VERSION"
    echo
    echo "Refusing to continue with an inconsistent Plasma stack."
    exit 1
fi

echo "    Plasma versions are aligned."

echo "==> Cleaning package metadata and caches"

"${DNF[@]}" clean all

sudo rm -rf \
    "$ROOTFS/var/cache/dnf" \
    "$ROOTFS/var/cache/libdnf5"

echo
echo "Debloat complete."
