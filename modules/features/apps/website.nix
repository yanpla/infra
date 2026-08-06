{
  # Serves yanpla.nl with hive, fronted by nginx with ACME TLS.
  den.aspects.website.nixos =
    { inputs, ... }:
    {
      imports = [ inputs.hive.nixosModules.default ];

      services.hive = {
        enable = true;
        # nginx is the only public listener. The control API and asset service
        # retain hive's loopback-only defaults.
        listen = "127.0.0.1:8080";
      };

      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        virtualHosts."yanpla.nl" = {
          # No www CNAME exists; add one before re-adding a www alias here.
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://127.0.0.1:8080";
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
