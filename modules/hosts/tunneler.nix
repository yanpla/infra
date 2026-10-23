{ config, inputs, ... }:
let
  nixos = config.modules.nixos;
  net = inputs.infra-private.hostNetworking.tunneler;
in
{
  hosts.tunneler = {
    imports = [
      nixos.default
      nixos.tunneler-hardware
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
