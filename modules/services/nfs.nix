{ ... }:

{
  # NFS Server (disabled by default - uncomment to enable)
  services.nfs.server = {
    enable = false;  # Set to true to enable NFS

    # NFS exports - adjust IP ranges for your network
    exports = ''
      # Media (read-only for all clients on LAN)
      /storage/media 192.168.1.0/24(ro,sync,no_subtree_check,crossmnt,fsid=0)

      # Media (read-write for specific trusted clients)
      /storage/media 192.168.1.100(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=100)

      # Audiobooks (read-write for trusted clients)
      /storage/audiobooks 192.168.1.0/24(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=100)

      # Syncthing (read-write)
      /storage/syncthing/sync 192.168.1.0/24(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=100)
    '';
  };

  # Open firewall for NFS (only if NFS is enabled)
  networking.firewall = {
    # NFS requires these ports: 2049 (NFS), 111 (portmapper), 4000-4002 (mountd, statd, lockd)
    allowedTCPPorts = [ ]; # Add: 111 2049 4000 4001 4002 when enabling NFS
    allowedUDPPorts = [ ]; # Add: 111 2049 4000 4001 4002 when enabling NFS
  };

  # Lock NFS to specific ports for easier firewall management
  services.nfs.server.lockdPort = 4001;
  services.nfs.server.mountdPort = 4002;
  services.nfs.server.statdPort = 4000;
}
