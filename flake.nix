{
  description = "NixOS configuration for deltaguppy-nixos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      # Configuration variables - change these values as needed
      hostname = "deltaguppy-nixos";
      username = "fortydeux";
      system = "x86_64-linux";
      # ZFS host ID (unique identifier) - generate with: head -c 8 /etc/machine-id
      hostId = "5f6f61fe";
    in
    {
      nixosConfigurations = {
        ${hostname} = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit hostname username hostId;
          };
          modules = [
            ./system-config/configuration.nix
            ./system-config/hardware-configuration.nix
            ./modules/zfs.nix
            ./modules/networking.nix
            ./modules/services
          ];
        };
      };
    };
}
