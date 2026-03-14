{ ... }:

{
  imports = [
    ./jellyfin.nix
    ./audiobookshelf.nix
    ./syncthing.nix
    ./samba.nix
    # ./nfs.nix  # Uncomment to enable NFS (for Linux clients)
  ];
}
