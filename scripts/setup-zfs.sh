#!/usr/bin/env nix-shell
#! nix-shell -i bash -p gptfdisk util-linux zfs
set -e  # Exit on error

# Auto-detect username (user who ran sudo)
if [ -n "$SUDO_USER" ]; then
    USERNAME="$SUDO_USER"
else
    echo "Error: This script must be run with sudo"
    echo "Usage: sudo ./setup-zfs.sh"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Home Server ZFS Setup Script"
echo "=========================================="
echo ""
echo "Detected user: $USERNAME"
echo "Flake directory: $FLAKE_DIR"
echo ""
echo "WARNING: This will DESTROY all data on:"
echo "  - /dev/sda"
echo "  - /dev/sdb"
echo "  - /dev/sdc"
echo "  - /dev/sdd"
echo ""
read -p "Type 'YES' to continue: " confirm

if [ "$confirm" != "YES" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Phase 1: Wiping drives..."
wipefs -a /dev/sdd1 2>/dev/null || true
sgdisk --zap-all /dev/sda
sgdisk --zap-all /dev/sdb
sgdisk --zap-all /dev/sdc
sgdisk --zap-all /dev/sdd
echo "✓ Drives wiped"

echo ""
echo "Phase 2: Creating ZFS pool..."
zpool create -f \
  -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  -O mountpoint=none \
  storage raidz2 \
  /dev/disk/by-id/ata-ST16000NE000-3UN101_ZVTHQX4A \
  /dev/disk/by-id/ata-ST16000NE000-3UN101_WVT1755D \
  /dev/disk/by-id/ata-ST16000NE000-3UN101_ZVTJ278J \
  /dev/disk/by-id/ata-ST16000NE000-2RW103_ZL2EMSN1

echo "✓ ZFS pool 'storage' created"

echo ""
echo "Phase 3: Creating datasets..."

# Media datasets (1M recordsize for large files)
zfs create -o mountpoint=legacy -o recordsize=1M storage/media
zfs create -o mountpoint=legacy storage/media/movies
zfs create -o mountpoint=legacy storage/media/tv
zfs create -o mountpoint=legacy storage/media/music

# Audiobooks
zfs create -o mountpoint=legacy -o recordsize=1M storage/audiobooks
zfs create -o mountpoint=legacy storage/audiobooks/library

# Syncthing
zfs create -o mountpoint=legacy storage/syncthing
zfs create -o mountpoint=legacy storage/syncthing/sync

# Shared folder (general NAS storage)
zfs create -o mountpoint=legacy storage/shared

# Application data (128K recordsize for databases)
zfs create -o mountpoint=legacy -o recordsize=128K storage/appdata
zfs create -o mountpoint=legacy storage/appdata/jellyfin
zfs create -o mountpoint=legacy storage/appdata/audiobookshelf
zfs create -o mountpoint=legacy storage/appdata/syncthing

echo "✓ All datasets created"

echo ""
echo "Phase 4: Creating mount directories..."
mkdir -p /storage/media/{movies,tv,music}
mkdir -p /storage/audiobooks/library
mkdir -p /storage/syncthing/sync
mkdir -p /storage/shared
mkdir -p /var/lib/{jellyfin,audiobookshelf,syncthing}
echo "✓ Mount directories created"

echo ""
echo "Phase 5: Setting permissions..."
# Note: These will be recreated by NixOS, but we set them now for consistency
chown -R root:root /storage/media
chown -R root:root /storage/audiobooks
chown -R "$USERNAME:users" /storage/syncthing
chown -R "$USERNAME:users" /storage/shared

echo "✓ Permissions set"

echo ""
echo "=========================================="
echo "ZFS Setup Complete!"
echo "=========================================="
echo ""
echo "Pool Status:"
zpool status storage
echo ""
echo "Datasets:"
zfs list -r storage
echo ""
echo "Next Steps:"
echo "1. Uncomment the dataset mounts in: $FLAKE_DIR/modules/zfs.nix"
echo "   (Remove # from fileSystems blocks starting around line 29)"
echo "2. Run: sudo nixos-rebuild build --flake $FLAKE_DIR#<hostname>"
echo "3. If successful: sudo nixos-rebuild switch --flake $FLAKE_DIR#<hostname>"
echo "4. Set permissions: sudo chown -R jellyfin:jellyfin /var/lib/jellyfin /storage/media"
echo "5. Verify services: systemctl status jellyfin audiobookshelf syncthing"
echo ""
