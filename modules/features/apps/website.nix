{
  # Serves yanpla.nl with hive, fronted by nginx with ACME TLS.
  den.aspects.website.nixos =
    { inputs, lib, ... }:
    {
      imports = [ inputs.hive.nixosModules.default ];

      services.hive = {
        enable = true;
        # nginx is the only public listener. The control API and asset service
        # retain hive's loopback-only defaults.
        listen = "127.0.0.1:9080";
        s3AssetStorage = {
          endpoint = "http://zimaboard:9000";
          bucket = "hive-assets";
          accessKeyFile = "/etc/hive-s3-access-key";
          secretKeyFile = "/etc/hive-s3-secret-key";
        };
        localServices.cloudflare-os = {
          address = "127.0.0.1:9180";
          allowedWorkers = [ "cloudflare-os" ];
        };
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
          locations."/".proxyPass = "http://127.0.0.1:9080";
        };
        virtualHosts."agents.yanpla.nl" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:9080";
            proxyWebsockets = true;
          };
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
