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
      nixos.grub-removable
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
  };
}
