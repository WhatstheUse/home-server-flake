{ config, pkgs, hostId, ... }:

{
  # ZFS Configuration
  networking.hostId = hostId;

  boot.supportedFilesystems = [ "zfs" ];
  # Use default kernel (stable LTS) - ZFS support is built-in
  # If ZFS compatibility issues arise, pin to specific LTS: boot.kernelPackages = pkgs.linuxPackages_6_6;
  boot.zfs.extraPools = [ "storage" ];

  # ZFS Services
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    autoSnapshot = {
      enable = true;
      frequent = 4;  # Keep 4 15-minute snapshots
      hourly = 24;   # Keep 24 hourly snapshots
      daily = 7;     # Keep 7 daily snapshots
      weekly = 4;    # Keep 4 weekly snapshots
      monthly = 12;  # Keep 12 monthly snapshots
    };
  };

  # Dataset Mounts

  fileSystems."/storage/media/movies" = {
    device = "storage/media/movies";
    fsType = "zfs";
    neededForBoot = false;
  };

  fileSystems."/storage/media/tv" = {
    device = "storage/media/tv";
    fsType = "zfs";
    neededForBoot = false;
  };

  fileSystems."/storage/media/music" = {
    device = "storage/media/music";
    fsType = "zfs";
    neededForBoot = false;
  };

  fileSystems."/storage/audiobooks/library" = {
    device = "storage/audiobooks/library";
    fsType = "zfs";
    neededForBoot = false;
  };

  fileSystems."/storage/syncthing/sync" = {
    device = "storage/syncthing/sync";
    fsType = "zfs";
    neededForBoot = false;
  };

  fileSystems."/storage/shared" = {
    device = "storage/shared";
    fsType = "zfs";
    neededForBoot = false;
  };

  fileSystems."/var/lib/jellyfin" = {
    device = "storage/appdata/jellyfin";
    fsType = "zfs";
    neededForBoot = false;
  };

  fileSystems."/var/lib/audiobookshelf" = {
    device = "storage/appdata/audiobookshelf";
    fsType = "zfs";
    neededForBoot = false;
  };

  fileSystems."/var/lib/syncthing" = {
    device = "storage/appdata/syncthing";
    fsType = "zfs";
    neededForBoot = false;
  };
}
