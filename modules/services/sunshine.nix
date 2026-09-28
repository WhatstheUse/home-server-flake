{ config, pkgs, ... }:

{
  # Sunshine — self-hosted game/desktop stream host for Moonlight clients.
  #
  # SECURITY: Sunshine's web UI (port 47990) can run arbitrary commands as the
  # session user, and a paired client has full keyboard/mouse/gamepad control of
  # the desktop. We therefore DO NOT open the firewall here — access is expected
  # only over Tailscale, whose interface (tailscale0) is already fully trusted in
  # modules/networking.nix. Connect Moonlight to this machine's 100.x.x.x address.
  services.sunshine = {
    enable = true;

    # Keep every Sunshine port (TCP 47984/47989/47990/48010, UDP 47998-48000/48010)
    # off the general firewall. Do NOT set this to true — it would expose the
    # command-capable web UI to the LAN. Tailscale traffic bypasses the firewall.
    openFirewall = false;

    # Required for KMS screen capture under Wayland (Plasma 6 defaults to Wayland).
    # This grants the Sunshine wrapper CAP_SYS_ADMIN (near root-equivalent), so it
    # is only acceptable because network access is restricted to Tailscale.
    capSysAdmin = true;
  };
}
