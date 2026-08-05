{ den, inputs, ... }:
let
  net = inputs.infra-private.hostNetworking.tunneler;
in
{
  den.aspects.tunneler = {
    includes = [
      den.aspects.server
      den.aspects.tunneler-hardware
      den.aspects.postfix
      den.aspects.calagopus-wings
    ];
    nixos = {
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
  };
}
