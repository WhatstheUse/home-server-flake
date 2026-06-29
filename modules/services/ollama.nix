{ config, pkgs, ... }:

{
  # Ollama LLM Service
  services.ollama = {
    enable = true;
    # CPU-only inference for Intel i3-N305 (no discrete GPU).
    package = pkgs.ollama-cpu;
    # Localhost only — OpenCode and Home Assistant run on the same machine.
    # If cross-machine access is ever needed, use Tailscale ACLs rather than
    # binding to 0.0.0.0.
    host = "127.0.0.1";
    port = 11434;
    # Models are stored in /var/lib/ollama/models.
    # After first nixos-rebuild, pull the default model:
    #   ollama pull qwen3:4b
    # Alternative once Gemma 4 community testing matures:
    #   ollama pull gemma4:e2b
  };

  # Resource caps — the NixOS ollama module already applies systemd security
  # hardening (DynamicUser, etc.), so we only add resource limits here.
  # ZFS ARC will yield RAM automatically when Ollama needs it.
  systemd.services.ollama.serviceConfig = {
    MemoryMax = "8G";   # Safety ceiling; leaves room for HA, ZFS ARC, other services
    CPUQuota = "400%";  # 4 of 8 cores; keeps the system responsive during inference
  };

  # Firewall: Ollama binds to 127.0.0.1 so no rule is needed.
  # Uncomment only if host is changed to 0.0.0.0:
  # networking.firewall.allowedTCPPorts = [ 11434 ];
}
