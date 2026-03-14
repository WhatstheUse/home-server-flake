{ username, ... }:

{
  # Samba File Sharing
  services.samba = {
    enable = true;
    openFirewall = true;

    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "Home Server";
        "netbios name" = "homeserver";
        "security" = "user";
        "guest account" = "nobody";
        "map to guest" = "bad user";

        # Performance tuning
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY";
        "read raw" = "yes";
        "write raw" = "yes";
        "server signing" = "no";
        "strict locking" = "no";
        "min receivefile size" = "16384";
        "use sendfile" = "yes";
        "aio read size" = "16384";
        "aio write size" = "16384";

        # macOS compatibility
        "vfs objects" = "fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:nfs_aces" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
      };

      # Media share (read-only for general access)
      media = {
        "path" = "/storage/media";
        "browseable" = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
        "comment" = "Media Library";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = username;
      };

      # Media writable (for managing content)
      "media-rw" = {
        "path" = "/storage/media";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "comment" = "Media Library (Read/Write)";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = username;
        "force user" = username;
      };

      # Audiobooks
      audiobooks = {
        "path" = "/storage/audiobooks";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "comment" = "Audiobooks";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = username;
        "force user" = username;
      };

      # Syncthing sync folder
      syncthing = {
        "path" = "/storage/syncthing/sync";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "comment" = "Syncthing Sync";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = username;
        "force user" = username;
      };

      # General shared folder (optional)
      shared = {
        "path" = "/storage/shared";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "comment" = "Shared Files";
        "create mask" = "0664";
        "directory mask" = "0775";
        "valid users" = username;
        "force user" = username;
      };
    };
  };

  # Allow Samba through firewall (ports already opened by openFirewall = true)
  # SMB ports: 139, 445 (TCP), 137, 138 (UDP)
}
