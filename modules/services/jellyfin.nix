{ config, pkgs, ... }:

{
  # Jellyfin Media Server
  services.jellyfin = {
    enable = true;
    dataDir = "/var/lib/jellyfin";
  };

  # Hardware acceleration for Intel Quick Sync
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # VAAPI support for newer Intel GPUs
      intel-compute-runtime  # OpenCL support
    ];
  };

  # Add jellyfin user to required groups for hardware transcoding and media access
  users.users.jellyfin.extraGroups = [ "video" "render" "media" ];

  # Create symlink for media access
  systemd.tmpfiles.rules = [
    "L+ /var/lib/jellyfin/media - - - - /storage/media"
  ];
}
