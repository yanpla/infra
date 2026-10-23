{ config, inputs, ... }:
let
  nixos = config.flake.modules.nixos;
  net = inputs.infra-private.hostNetworking.tunneler;
in
{
  hosts.tunneler = {
    imports = [
      ./hardware-configuration.nix
      nixos.default
      nixos.postfix
      nixos.calagopus-wings
    ];

    networking.useDHCP = false;
    networking.interfaces.${net.interface} = {
      useDHCP = false;
      ipv4.addresses = [
        {
          inherit (net) address prefixLength;
        }
      ];
    };
    networking.defaultGateway = {
      address = net.gateway;
      interface = net.interface;
    };
    networking.nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    system.stateVersion = "25.11";

    # GRUB on the removable EFI path, with a BIOS boot partition as legacy fallback.
    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
