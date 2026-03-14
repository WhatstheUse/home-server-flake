{ ... }:

{
  # Firewall Configuration
  networking.firewall = {
    enable = true;

    # Service ports
    allowedTCPPorts = [
      8096   # Jellyfin
      8384   # Syncthing GUI
      13378  # Audiobookshelf
      22000  # Syncthing sync
    ];

    allowedUDPPorts = [
      21027  # Syncthing discovery
    ];

    # Trust Tailscale interface completely
    trustedInterfaces = [ "tailscale0" ];

    # SSH only via Tailscale
    interfaces.tailscale0.allowedTCPPorts = [ 22 ];
  };
}
