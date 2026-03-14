# NixOS Home Server Configuration

A declarative NixOS configuration for a home media server with ZFS RAIDZ2 storage, hardware-accelerated transcoding, and automated maintenance.

## Features

**Storage:**
- ZFS RAIDZ2 pool with 4x drives (~50% usable capacity, 2-disk fault tolerance)
- Automated snapshots (15-min/hourly/daily/weekly/monthly retention)
- Weekly scrubbing for data integrity
- Optimized recordsize per dataset type

**Services:**
- **Jellyfin** - Media server with Intel Quick Sync hardware transcoding (VAAPI)
- **Audiobookshelf** - Audiobook and podcast server
- **Syncthing** - File synchronization
- **Samba** - Network file sharing (NAS functionality for Windows/Mac/Linux)
- **Tailscale** - Secure remote access
- **Mullvad VPN** - Privacy-focused VPN service

**Desktop:**
- KDE Plasma 6 for local management
- Flatpak support with Flathub repository (install apps via Discover)
- Pre-configured with helix, fish, yazi, and other productivity tools

## Architecture

```
├── flake.nix                      # Main entry point, configuration variables
├── system-config/
│   ├── configuration.nix          # System configuration, packages, users
│   └── hardware-configuration.nix # Hardware-specific settings
├── modules/
│   ├── zfs.nix                   # ZFS pool, datasets, snapshots, scrubbing
│   ├── networking.nix            # Firewall rules, port configuration
│   └── services/
│       ├── jellyfin.nix          # Jellyfin with hardware transcoding
│       ├── audiobookshelf.nix    # Audiobookshelf configuration
│       ├── syncthing.nix         # Syncthing file sync
│       └── default.nix           # Service module aggregator
└── scripts/
    ├── setup-zfs.sh              # ZFS pool and dataset creation
    └── verify-setup.sh           # Post-installation verification
```

## Prerequisites

- NixOS 24.11 or later installed on an NVMe/SSD boot drive
- 4x identical SATA drives for ZFS pool (will be wiped)
- Intel CPU with integrated graphics (for Quick Sync)
- Backup of any important data on the drives

## Installation

### 1. Clone and Customize

```bash
# Clone the repository
git clone https://github.com/yourusername/homeServeFlake.git
cd homeServeFlake

# Edit configuration variables in flake.nix
nano flake.nix
```

**Required customizations in `flake.nix`:**
```nix
hostname = "your-hostname";      # Your system hostname
username = "your-username";      # Your user account name
hostId = "12345678";            # Generate: head -c 8 /etc/machine-id
```

**Optional customizations:**
- Edit `scripts/setup-zfs.sh` if your drive IDs differ (check with `ls -l /dev/disk/by-id/`)
- Edit `modules/zfs.nix` to adjust snapshot retention or pool name
- Edit `modules/networking.nix` to change service ports
- Edit `system-config/configuration.nix` to add/remove packages

### 2. Initial System Setup (Stage 1: Enable ZFS)

This stage enables ZFS kernel support without creating the pool yet:

```bash
# Build and switch to enable ZFS kernel modules
sudo nixos-rebuild switch --flake .#your-hostname

# Reboot to load the new kernel with ZFS support
sudo reboot
```

### 3. Create ZFS Pool (Stage 2: After Reboot)

**⚠️ WARNING: This will DESTROY all data on your SATA drives!**

```bash
cd /path/to/homeServeFlake

# Run the ZFS setup script
sudo ./scripts/setup-zfs.sh
```

This script will:
1. Confirm you want to proceed (type 'YES')
2. Wipe all drives completely
3. Create ZFS RAIDZ2 pool named "storage"
4. Create optimized datasets for media, audiobooks, and app data
5. Set up mount directories

Expected output: "ZFS Setup Complete!" with pool status showing ONLINE.

### 4. Enable Dataset Mounts and Services

After the ZFS pool is created, uncomment the dataset mounts:

**Edit `modules/zfs.nix`:**
- Remove the `#` characters from all `fileSystems` blocks (lines ~29-72)
- Change the comment from "Dataset Mounts - COMMENTED OUT..." to just "# Dataset Mounts"

**Then rebuild:**
```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

### 5. Set Permissions

```bash
# Jellyfin permissions
sudo chown -R jellyfin:jellyfin /var/lib/jellyfin /storage/media

# Audiobookshelf permissions
sudo chown -R audiobookshelf:audiobookshelf /var/lib/audiobookshelf /storage/audiobooks

# Syncthing permissions (use your username)
sudo chown -R your-username:users /var/lib/syncthing /storage/syncthing
```

### 6. Verify Installation

```bash
./scripts/verify-setup.sh
```

Check for green checkmarks (✓) on:
- ZFS pool ONLINE
- All 8 datasets mounted
- Services running (jellyfin, audiobookshelf, syncthing)
- Hardware transcoding available
- Network ports listening

## Initial Service Configuration

Get your server IP address:
```bash
hostname -I | awk '{print $1}'
```

### Jellyfin (port 8096)

1. Open: `http://server-ip:8096`
2. Complete setup wizard, create admin account
3. Add media libraries:
   - **Movies**: `/var/lib/jellyfin/media/movies`
   - **TV Shows**: `/var/lib/jellyfin/media/tv`
   - **Music**: `/var/lib/jellyfin/media/music`
4. Enable hardware transcoding:
   - Navigate to: **Dashboard → Playback → Transcoding**
   - Set **Hardware acceleration**: "Video Acceleration API (VAAPI)"
   - Set **VA-API Device**: `/dev/dri/renderD128`
   - Enable: H264, HEVC, VP9, AV1

### Audiobookshelf (port 13378)

1. Open: `http://server-ip:13378`
2. Create admin account
3. Add library pointing to: `/storage/audiobooks/library`
4. Configure metadata preferences

### Syncthing (port 8384)

1. Open: `http://server-ip:8384`
2. Note your device ID for pairing with other devices
3. Add folders within `/storage/syncthing/sync`
4. Connect to other Syncthing devices

## NAS (Network File Sharing)

The server includes Samba for cross-platform network file sharing. After rebuild, your storage will be accessible from any device on your network.

### Setting Up Samba User

Before accessing shares, set a Samba password for your user:

```bash
# Set Samba password (can be different from your system password)
sudo smbpasswd -a your-username
```

### Available Network Shares

**From Windows:**
1. Open File Explorer
2. In address bar, type: `\\server-ip\` or `\\homeserver\`
3. Enter your username and Samba password

**From macOS:**
1. Finder → Go → Connect to Server (Cmd+K)
2. Enter: `smb://server-ip/` or `smb://homeserver/`
3. Enter your username and Samba password

**From Linux:**
```bash
# Mount a share
sudo mount -t cifs //server-ip/media /mnt/media -o username=your-username

# Or add to /etc/fstab for automatic mounting:
//server-ip/media /mnt/media cifs username=your-username,password=your-password,uid=1000,gid=100 0 0
```

**Available Shares:**
- `media` - Read-only access to media library (guest access allowed)
- `media-rw` - Read-write access to media library (requires authentication)
- `audiobooks` - Read-write access to audiobooks (requires authentication)
- `syncthing` - Read-write access to Syncthing sync folder (requires authentication)
- `shared` - General shared storage (requires authentication)

### NFS Alternative (Optional - Linux Only)

If you have Linux clients and want better performance, you can enable NFS:

1. Edit `modules/services/nfs.nix`:
   - Change `enable = false;` to `enable = true;`
   - Update IP ranges to match your network (default: 192.168.1.0/24)
   - Update `anonuid` and `anongid` to match your user ID (check with `id`)

2. Uncomment NFS in `modules/services/default.nix`:
   - Remove `#` from `# ./nfs.nix`

3. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake .#your-hostname
   ```

4. Mount from Linux clients:
   ```bash
   # Mount media (read-only)
   sudo mount -t nfs server-ip:/storage/media /mnt/media

   # Add to /etc/fstab for automatic mounting:
   server-ip:/storage/media /mnt/media nfs defaults,noatime 0 0
   ```

### Performance Tips

**Samba:**
- Already optimized for performance in the configuration
- Supports macOS Time Machine (if needed, add Time Machine share)
- Uses sendfile and async I/O for better throughput

**NFS:**
- Better performance for Linux clients than Samba
- Lower CPU overhead
- Native to Unix-like systems

**Security:**
- Samba shares are password-protected (except read-only media share)
- Consider using Tailscale for secure remote access to shares
- NFS is less secure - only enable on trusted networks

## ZFS Dataset Structure

```
storage/                                    # Pool root (29TB usable)
├── media/                                  # Jellyfin media (1M recordsize)
│   ├── movies/          → /storage/media/movies
│   ├── tv/              → /storage/media/tv
│   └── music/           → /storage/media/music
├── audiobooks/                             # Audiobookshelf (1M recordsize)
│   └── library/         → /storage/audiobooks/library
├── syncthing/                              # Syncthing data
│   └── sync/            → /storage/syncthing/sync
├── shared/              → /storage/shared  # General NAS storage
└── appdata/                                # Service data (128K recordsize)
    ├── jellyfin/        → /var/lib/jellyfin
    ├── audiobookshelf/  → /var/lib/audiobookshelf
    └── syncthing/       → /var/lib/syncthing
```

## Firewall Configuration

**Open Ports:**
- 8096 (TCP) - Jellyfin
- 8384 (TCP) - Syncthing GUI
- 13378 (TCP) - Audiobookshelf
- 22000 (TCP) - Syncthing sync
- 21027 (UDP) - Syncthing discovery
- 139, 445 (TCP) - Samba/SMB file sharing
- 137, 138 (UDP) - Samba/SMB discovery

**Security:**
- SSH (port 22) only accessible via Tailscale
- Firewall enabled by default
- All services accessible on LAN
- Samba shares password-protected (except read-only media share)

## Maintenance

### Check ZFS Health

```bash
# Pool status
zpool status storage

# Capacity
zpool list storage

# All datasets
zfs list -r storage

# View snapshots
zfs list -t snapshot | grep storage

# Manual scrub
sudo zpool scrub storage
```

### Service Management

```bash
# Check service status
systemctl status jellyfin audiobookshelf syncthing

# View logs
journalctl -u jellyfin -f
journalctl -u audiobookshelf -f
journalctl -u syncthing -f

# Restart a service
sudo systemctl restart jellyfin
```

### Update System

```bash
# Update flake lock
nix flake update

# Rebuild with new packages
sudo nixos-rebuild switch --flake .#your-hostname
```

### ZFS Snapshots

Automated snapshots are configured with the following retention:
- Frequent (15-min): Keep 4 (1 hour)
- Hourly: Keep 24 (1 day)
- Daily: Keep 7 (1 week)
- Weekly: Keep 4 (1 month)
- Monthly: Keep 12 (1 year)

**Restore from snapshot:**
```bash
# List snapshots
zfs list -t snapshot

# Rollback to a snapshot
sudo zfs rollback storage/media/movies@autosnap_2026-03-14_12:00:00_daily

# Clone a snapshot (non-destructive)
sudo zfs clone storage/media/movies@autosnap_2026-03-14_12:00:00_daily storage/media/movies-restored
```

## Troubleshooting

### ZFS Pool Won't Import

```bash
# Check available pools
sudo zpool import

# Force import
sudo zpool import -f storage
```

### Service Won't Start

```bash
# Check detailed status
systemctl status service-name --no-pager -l

# Check recent logs
journalctl -u service-name -n 100

# Check file permissions
ls -la /var/lib/service-name
ls -la /storage/relevant-directory
```

### Hardware Transcoding Not Working

```bash
# Verify GPU device exists
ls -la /dev/dri/renderD128

# Check jellyfin user groups
groups jellyfin
# Should show: jellyfin video render

# If groups are missing, rebuild
sudo nixos-rebuild switch --flake .#your-hostname
```

### Dataset Permission Issues

```bash
# Reset ownership (replace your-username with actual username)
sudo chown -R jellyfin:jellyfin /var/lib/jellyfin /storage/media
sudo chown -R audiobookshelf:audiobookshelf /var/lib/audiobookshelf /storage/audiobooks
sudo chown -R your-username:users /var/lib/syncthing /storage/syncthing
```

### System Won't Boot After Changes

1. At boot menu, select a previous generation
2. Once booted, rollback:
   ```bash
   sudo nixos-rebuild switch --rollback
   ```

## Accessing Storage in File Manager

ZFS datasets are mounted as regular directories. To access in Dolphin or other file managers:

**Method 1: Navigate directly**
- Type `/storage/media/` in the address bar

**Method 2: Create bookmarks**
- Navigate to `/storage/media/`
- Right-click sidebar → "Add to Places"

**Method 3: Symlinks in home directory**
```bash
ln -s /storage/media ~/Media
ln -s /storage/audiobooks ~/Audiobooks
ln -s /storage/syncthing ~/Syncthing
```

## Installing Applications with Flatpak

Flatpak support is enabled with the Flathub repository pre-configured. You can install applications using either the GUI or command line.

### Using KDE Discover (GUI)

1. Open **Discover** from the application menu
2. Click the hamburger menu (☰) in the top-left
3. Select **Settings**
4. Ensure Flatpak is enabled as a source
5. Browse and install apps directly from Discover

Popular Flatpak apps for media servers:
- **VLC** - Media player
- **Kodi** - Media center interface
- **FileZilla** - FTP client for uploading media
- **Handbrake** - Video transcoding
- **MakeMKV** - Blu-ray ripping

### Using Command Line

```bash
# Search for an app
flatpak search vlc

# Install an app
flatpak install flathub org.videolan.VLC

# List installed apps
flatpak list

# Update all apps
flatpak update

# Remove an app
flatpak uninstall org.videolan.VLC
```

### Managing Flatpak Storage

Flatpak apps are stored in `/var/lib/flatpak` (system) and `~/.local/share/flatpak` (user).

```bash
# Check Flatpak disk usage
du -sh /var/lib/flatpak ~/.local/share/flatpak

# Remove unused runtimes
flatpak uninstall --unused
```

### Why Flatpak on NixOS?

While NixOS has its own package manager, Flatpak is useful for:
- **Proprietary apps** not available in nixpkgs
- **Latest versions** of GUI applications
- **Sandboxed apps** with better security isolation
- **Easy updates** through Discover GUI

For system services and CLI tools, continue using Nix packages in `configuration.nix`.

## Using Mullvad VPN

Mullvad VPN is pre-installed and ready to use. You'll need a Mullvad account to use the service.

### Initial Setup

1. **Get a Mullvad Account**
   - Visit https://mullvad.net/
   - Generate an account number (no email required)
   - Add time to your account

2. **Login via GUI**
   - Launch **Mullvad VPN** from the application menu
   - Enter your account number
   - Click **Login**

3. **Or Login via CLI**
   ```bash
   # Set account number
   mullvad account login YOUR_ACCOUNT_NUMBER

   # Check account status
   mullvad account get
   ```

### Basic Usage

**GUI Method:**
- Open Mullvad VPN app
- Click **Connect** / **Disconnect**
- Change server location from the location list
- Configure settings in preferences

**CLI Method:**
```bash
# Connect to VPN
mullvad connect

# Disconnect from VPN
mullvad disconnect

# Check connection status
mullvad status

# List available countries
mullvad relay list

# Set specific location
mullvad relay set location se got  # Sweden, Gothenburg

# Enable auto-connect
mullvad auto-connect set on

# Enable LAN access (important for accessing your NAS)
mullvad lan set allow
```

### Important Configuration for Home Server

Since this is a home server with local network services, you need to allow LAN access:

```bash
# Allow local network access (Samba, Jellyfin, etc.)
mullvad lan set allow

# Check current setting
mullvad lan get
```

This ensures you can still access:
- Jellyfin (port 8096)
- Samba shares
- Syncthing
- Other local services

### Split Tunneling (Optional)

If you want certain applications to bypass the VPN:

```bash
# Add application to split tunnel exclusions
mullvad split-tunnel add /usr/bin/application-name

# List excluded applications
mullvad split-tunnel list

# Remove from exclusions
mullvad split-tunnel delete /usr/bin/application-name
```

### Use Cases for VPN on Home Server

1. **Private Torrent Downloads** - Use with transmission-daemon or qBittorrent
2. **Secure Remote Access** - Extra layer when accessing server remotely
3. **Privacy for Outbound Traffic** - Protects server's internet activity
4. **Geo-restricted Content** - Access region-locked media sources

### VPN + Tailscale

Both Mullvad and Tailscale can run simultaneously:
- **Mullvad** - Protects outbound internet traffic
- **Tailscale** - Secure access to your server from anywhere

They work on different network layers and don't conflict.

### Checking VPN Status

```bash
# Quick status check
mullvad status

# Detailed information
mullvad status -v

# Check current IP and location
curl https://am.i.mullvad.net/json
```

### Troubleshooting

**Issue: Can't access local services when VPN is on**
```bash
# Make sure LAN access is allowed
mullvad lan set allow
```

**Issue: VPN won't connect**
```bash
# Check daemon status
systemctl status mullvad-daemon

# Restart daemon
sudo systemctl restart mullvad-daemon
```

**Issue: Need to exclude specific traffic**
- Use split tunneling (see above)
- Or use Mullvad's kill switch settings

### Security Best Practices

- ✅ Keep your account number private
- ✅ Enable auto-connect for always-on protection
- ✅ Use WireGuard protocol (default, faster)
- ✅ Enable kill switch to prevent leaks
- ✅ Regularly check connection: `mullvad status`

## Storage Capacity Planning

With 4x 16TB drives in RAIDZ2:
- **Raw capacity**: 64TB
- **Usable capacity**: ~29TB (shown in output)
- **Overhead**: ~35TB (2 drives parity + ZFS metadata)

**Suggested allocation:**
- Jellyfin media: 20-25TB
- Audiobooks: 2TB
- Syncthing: 2-4TB
- Snapshots/overhead: Remaining

ZFS compression (lz4) typically provides 1.2-1.5x space savings on media.

## Advanced Configuration

### Change ZFS Pool Name

Edit `modules/zfs.nix` and `scripts/setup-zfs.sh`, replacing "storage" with your preferred name.

### Add More Services

Create new module files in `modules/services/`, then add to `modules/services/default.nix`.

### Adjust Snapshot Retention

Edit `modules/zfs.nix` and modify the `services.zfs.autoSnapshot` values.

### Add L2ARC (SSD Cache)

```bash
# Add SSD as cache device (non-destructive)
sudo zpool add storage cache /dev/disk/by-id/your-ssd-id
```

### Enable ZFS Deduplication (Not Recommended)

Deduplication requires significant RAM. Only enable if you have 1GB RAM per 1TB storage:
```bash
sudo zfs set dedup=on storage/media
```

## Contributing

This configuration is designed to be portable. To use on a different machine:

1. Fork the repository
2. Update `flake.nix` with your hostname, username, and hostId
3. Update `scripts/setup-zfs.sh` with your drive IDs
4. Adjust module configurations as needed
5. Follow the installation steps

## License

MIT License - Feel free to use and modify for your own systems.

## Support

For NixOS-specific questions: https://nixos.org/manual/nixos/stable/
For ZFS questions: https://openzfs.github.io/openzfs-docs/

## Acknowledgments

- NixOS community for the declarative configuration system
- OpenZFS project for reliable storage
- Jellyfin, Audiobookshelf, and Syncthing developers
