{ config, pkgs, hostId, ... }:

{
  # ZFS Configuration
  networking.hostId = hostId;

  boot.supportedFilesystems = [ "zfs" ];
  # Respect ZFS hostId guard rather than force-importing (new default from 26.11).
  # Safe here: root is ext4 and the "storage" pool is imported later via extraPools,
  # so this only guards against a genuine hostId mismatch (another host owning the pool).
  boot.zfs.forceImportRoot = false;
  # Use default kernel (stable LTS) - ZFS support is built-in
  # If ZFS compatibility issues arise, pin to specific LTS: boot.kernelPackages = pkgs.linuxPackages_6_6;
  boot.zfs.extraPools = [ "storage" ];

  # ZFS Services
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    # NOTE: zfstools' zfs-auto-snapshot is OPT-IN. It only snapshots datasets
    # that have com.sun:auto-snapshot=true. Enabling this service alone does
    # nothing until datasets are opted in (see zfs-auto-snapshot-optin below).
    autoSnapshot = {
      enable = true;
      frequent = 4;  # Keep 4 15-minute snapshots
      hourly = 24;   # Keep 24 hourly snapshots
      daily = 7;     # Keep 7 daily snapshots
      weekly = 4;    # Keep 4 weekly snapshots
      monthly = 12;  # Keep 12 monthly snapshots
    };
  };

  # Opt selected datasets into zfs-auto-snapshot so the schedule above actually
  # runs on them. This is what gives us rewind/undelete protection for the
  # Syncthing-managed media libraries: a propagated deletion removes the live
  # file but the snapshot retains it -> recover from .zfs/snapshot/...
  # The property lives in persistent pool metadata; we reassert it here on every
  # rebuild / pool re-import so it stays documented and reproducible.
  systemd.services.zfs-auto-snapshot-optin = {
    description = "Opt selected datasets into zfs-auto-snapshot";
    after = [ "zfs-import.target" ];
    wants = [ "zfs-import.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.zfs ];
    script = ''
      for ds in \
        storage/media/videos \
        storage/media/music \
        storage/audiobooks/library \
        storage/podcasts \
        storage/ebooks \
        storage/shared; do
        if zfs list -H -o name "$ds" >/dev/null 2>&1; then
          zfs set com.sun:auto-snapshot=true "$ds"
        fi
      done
    '';
  };

  # Dataset Mounts

  fileSystems."/storage/media/videos" = {
    device = "storage/media/videos";
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

  fileSystems."/storage/podcasts" = {
    device = "storage/podcasts";
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

  fileSystems."/storage/ebooks" = {
    device = "storage/ebooks";
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
