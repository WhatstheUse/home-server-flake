#!/usr/bin/env bash

echo "=========================================="
echo "Home Server Verification Script"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "=== ZFS Health ==="
if zpool status storage | grep -q "state: ONLINE"; then
    check_pass "ZFS pool 'storage' is ONLINE"
    zpool list storage
else
    check_fail "ZFS pool 'storage' is not ONLINE"
    zpool status storage
fi

echo ""
echo "=== ZFS Datasets ==="
echo "Expected: 9 datasets mounted"
MOUNTED=$(mount | grep -c "^storage/" || true)
if [ "$MOUNTED" -eq 9 ]; then
    check_pass "All 9 datasets mounted"
else
    check_warn "Only $MOUNTED/9 datasets mounted"
fi
mount | grep "^storage/"

echo ""
echo "=== Storage Capacity ==="
df -h | grep storage

echo ""
echo "=== Service Status ==="
for service in jellyfin audiobookshelf syncthing; do
    if systemctl is-active --quiet $service; then
        check_pass "$service is running"
    else
        check_fail "$service is not running"
        systemctl status $service --no-pager -l
    fi
done

echo ""
echo "=== Network Ports ==="
echo "Listening services:"
ss -tulpn | grep -E '8096|8384|13378|22000|21027' || check_warn "Some ports not listening"

echo ""
echo "=== Hardware Transcoding ==="
if [ -e /dev/dri/renderD128 ]; then
    check_pass "GPU device exists: /dev/dri/renderD128"
    ls -la /dev/dri/renderD128
else
    check_fail "GPU device not found: /dev/dri/renderD128"
fi

if id jellyfin | grep -q "render"; then
    check_pass "jellyfin user in 'render' group"
else
    check_fail "jellyfin user NOT in 'render' group"
fi

if id jellyfin | grep -q "video"; then
    check_pass "jellyfin user in 'video' group"
else
    check_fail "jellyfin user NOT in 'video' group"
fi

echo ""
echo "=== ZFS Automation ==="
if systemctl list-timers | grep -q "zfs-scrub"; then
    check_pass "ZFS auto-scrub timer configured"
    systemctl list-timers | grep zfs
else
    check_warn "ZFS auto-scrub timer not found"
fi

SNAPSHOTS=$(zfs list -t snapshot | tail -n +2 | wc -l)
if [ "$SNAPSHOTS" -gt 0 ]; then
    check_pass "ZFS snapshots enabled ($SNAPSHOTS snapshots found)"
    zfs list -t snapshot | head -n 10
else
    check_warn "No ZFS snapshots found yet (they may take time to appear)"
fi

echo ""
echo "=== Service URLs ==="
IP=$(hostname -I | awk '{print $1}')
echo "Jellyfin:        http://$IP:8096"
echo "Audiobookshelf:  http://$IP:13378"
echo "Syncthing:       http://$IP:8384"
echo ""
echo "=========================================="
echo "Verification Complete"
echo "=========================================="
