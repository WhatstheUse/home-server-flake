{ ... }:

{
  imports = [
    ./jellyfin.nix
    ./audiobookshelf.nix
    ./syncthing.nix
    ./samba.nix
    # ./nfs.nix  # Uncomment to enable NFS (for Linux clients)
    # ./ollama.nix  # Uncomment to enable Ollama LLM service
    # ./home-assistant.nix  # Uncomment to enable Home Assistant
    ../media-sharing.nix  # Shared media group and permissions
  ];
}
