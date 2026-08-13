{
  # Serves yanpla.nl from an isolated celld fleet, fronted by nginx with ACME TLS.
  den.aspects.website.nixos =
    { inputs, ... }:
    {
      imports = [ inputs.hive.nixosModules.default ];

      services.hive = {
        enable = true;
        applications.website = {
          project = inputs.website.packages.x86_64-linux.default;
          # This prefix is the website fleet's complete administrative and
          # durability boundary inside rustfs's hive bucket.
          bucket = "s3://hive/website";
          endpoint = "http://zimaboard:9000";
          region = "auto";
          publicListen = "127.0.0.1:9080";
          internalListen = "127.0.0.1:9081";
          accessKeyFile = "/etc/hive/s3-access-key";
          secretKeyFile = "/etc/hive/s3-secret-key";
          environmentFile = "/etc/website.env";
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
