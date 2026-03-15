{ username, ... }:

{
  # Syncthing File Synchronization
  services.syncthing = {
    enable = true;
    user = username;
    dataDir = "/storage/syncthing/sync";
    configDir = "/var/lib/syncthing/.config/syncthing";

    # Allow access from network
    guiAddress = "0.0.0.0:8384";

    # Open firewall ports automatically
    openDefaultPorts = true;

    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices = {};
      folders = {};
    };
  };

  # Grant Syncthing access to media storage locations
  systemd.services.syncthing.serviceConfig = {
    ReadWritePaths = [
      "/storage/syncthing"
      "/storage/media"
      "/storage/audiobooks"
      "/storage/ebooks"
    ];
  };
}
