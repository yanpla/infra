{ den, inputs, ... }:
let
  net = inputs.infra-private.hostNetworking.beta;
in
{
  den.aspects.beta = {
    includes = [
      den.aspects.server
      den.aspects.beta-hardware
      den.aspects.website
      den.aspects.starlight-web
      den.aspects.calagopus-panel
      den.aspects.calagopus-wings
    ];
    nixos = {
      # No DHCP on this network
      networking.useDHCP = false;
      systemd.network = {
        enable = true;
        networks."10-wan" = {
          matchConfig.MACAddress = net.mac;
          address = [ "${net.address}/${toString net.prefixLength}" ];
          routes = [
            {
              Gateway = net.gateway;
              GatewayOnLink = true;
            }
          ];
          networkConfig.DNS = [
            "1.1.1.1"
            "8.8.8.8"
          ];
          linkConfig.RequiredForOnline = "routable";
        };
      };
      networking.nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];

      system.stateVersion = "26.05";
    };
  };
}
