{ ... }:

{
  # Audiobookshelf Service
  services.audiobookshelf = {
    enable = true;
    # dataDir expects just the directory name, not full path
    # systemd automatically prepends /var/lib/
    dataDir = "audiobookshelf";
    host = "0.0.0.0";
    port = 13378;
  };

  # Allow access to audiobook storage
  systemd.services.audiobookshelf.serviceConfig = {
    ReadWritePaths = [ "/storage/audiobooks" ];
  };
}
