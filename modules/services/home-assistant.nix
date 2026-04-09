{ config, pkgs, ... }:

{
  # Home Assistant
  services.home-assistant = {
    enable = true;

    # Declarative base config. Most day-to-day configuration (automations,
    # dashboards, device integrations) is managed via the UI and lives in
    # /var/lib/hass/. Only structural settings belong here.
    config = {
      # default_config bundles the most common integrations including:
      # mobile_app (Android companion), conversation (Assist voice pipeline),
      # energy, history, logbook, and more.
      default_config = {};

      http = {
        server_host = "0.0.0.0";
        server_port = 8123;
        # If accessed via a reverse proxy, also set:
        # trusted_proxies = [ "127.0.0.1" ];
        # use_x_forwarded_for = true;
      };

      # Keep these as !include so the UI can manage them without conflicting
      # with this declarative config.
      automation = "!include automations.yaml";
      script     = "!include scripts.yaml";
      scene      = "!include scenes.yaml";
    };

    # Python packages needed by integrations.
    extraPackages = python3Packages: with python3Packages; [
      # Add integration-specific deps here as needed, e.g.:
      # python-matter-server
    ];

    # Components that need to be present in the HA Python environment.
    # default_config covers mobile_app and conversation; add extras here.
    extraComponents = [
      "assist_pipeline"  # Powers the voice Assist feature used by the Android app
      "tts"              # Text-to-speech for spoken responses
      "stt"              # Speech-to-text (configure provider via UI)
      "webhook"          # Enables webhook triggers used by the OpenCode bridge
    ];
  };

  # Firewall: keep closed and access via Tailscale only.
  # Uncomment if direct LAN access is needed:
  # networking.firewall.allowedTCPPorts = [ 8123 ];
}
