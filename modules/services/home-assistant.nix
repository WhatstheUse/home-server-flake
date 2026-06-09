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

      # REST command used by the voice automation to call the Claude bridge.
      # The bridge runs on localhost:8765 (ha-opencode-bridge user service).
      rest_command = {
        ask_claude = {
          url          = "http://127.0.0.1:8765/ask";
          method       = "POST";
          content_type = "application/json";
          payload      = "{\"text\": \"{{ text }}\"}";
          timeout      = 30;
        };
      };
    };

    # Python packages needed by integrations.
    extraPackages = python3Packages: with python3Packages; [
      # Add integration-specific deps here as needed, e.g.:
      # python-matter-server
    ];

    # Components that need to be present in the HA Python environment.
    # default_config covers mobile_app, conversation, webhook, etc.
    # Listing a component here ensures its Python dependencies are included
    # in the Nix build (HA runs with --skip-pip and cannot install at runtime).
    extraComponents = [
      "assist_pipeline"  # Voice Assist pipeline for Android companion app
      "stt"              # Speech-to-text base component
      "tts"              # Text-to-speech base component
      "google_translate" # Auto-configured by onboarding wizard (needs gtts)
      "met"              # Met.no weather (auto-discovered by onboarding)
      "radio_browser"    # Radio Browser (auto-discovered by onboarding)
      "mobile_app"       # Android/iOS companion app support
    ];
  };

  # Create the !include files that configuration.yaml references.
  # Without these, HA enters recovery mode on first boot.
  systemd.tmpfiles.rules = [
    "f /var/lib/hass/automations.yaml 0600 hass hass -"
    "f /var/lib/hass/scripts.yaml     0600 hass hass -"
    "f /var/lib/hass/scenes.yaml      0600 hass hass -"
  ];

  # Firewall: keep closed and access via Tailscale only.
  # Uncomment if direct LAN access is needed:
  # networking.firewall.allowedTCPPorts = [ 8123 ];
}
