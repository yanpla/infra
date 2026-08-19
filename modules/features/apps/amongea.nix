{
  den.aspects.amongea.nixos =
    { inputs, ... }:
    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        virtualHosts."amongea.yanpla.nl" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass =
            "http://${inputs.infra-private.hostNetworking.tunneler.address}:10000";
        };
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = "me@yanpla.nl";
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
