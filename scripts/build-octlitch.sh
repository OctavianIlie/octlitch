#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT"

STAGES=(
    scripts/01-extract-base.sh
    scripts/02-debloat.sh
    scripts/03-brand-system.sh
    scripts/04-plasma-rice.sh
    scripts/05-install-apps.sh
    scripts/06-patch-initrd.sh
    scripts/07-build-iso.sh
)

echo "==> Validating build scripts"

for stage in "${STAGES[@]}"; do
    if [[ ! -s "$PROJECT_ROOT/$stage" ]]; then
        echo "ERROR: Missing or empty build stage: $stage"
        exit 1
    fi

    if ! bash -n "$PROJECT_ROOT/$stage"; then
        echo "ERROR: Invalid Bash syntax: $stage"
        exit 1
    fi
done

for required in \
    plasma/bin/octlitch-first-login \
    plasma/bin/octlitch-sync-lockscreen
do
    if [[ ! -s "$PROJECT_ROOT/$required" ]]; then
        echo "ERROR: Missing or empty file: $required"
        exit 1
    fi
done

echo "======================================"
echo "         Octlitch ISO Builder"
echo "======================================"
echo

for stage in "${STAGES[@]}"; do
    echo
    echo "======================================"
    echo "==> Running: $stage"
    echo "======================================"
    echo

    "$PROJECT_ROOT/$stage"
done

echo
echo "======================================"
echo "Octlitch build completed successfully."
echo "======================================"
echo

ls -lh \
    "$PROJECT_ROOT/iso/output/Octlitch-dev-x86_64.iso" \
    "$PROJECT_ROOT/iso/output/Octlitch-dev-x86_64.iso.sha256"
