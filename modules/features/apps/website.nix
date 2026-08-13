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
        applications.bench1 = {
          project = inputs.website.packages.x86_64-linux.default;
          bucket = "s3://hive/bench1";
          endpoint = "http://zimaboard:9000";
          region = "auto";
          publicListen = "127.0.0.1:9090";
          internalListen = "127.0.0.1:9091";
          accessKeyFile = "/etc/hive/s3-access-key";
          secretKeyFile = "/etc/hive/s3-secret-key";
          environmentFile = "/etc/website.env";
        };
        applications.bench2 = {
          project = inputs.website.packages.x86_64-linux.default;
          bucket = "s3://hive/bench2";
          endpoint = "http://zimaboard:9000";
          region = "auto";
          publicListen = "127.0.0.1:9100";
          internalListen = "127.0.0.1:9101";
          accessKeyFile = "/etc/hive/s3-access-key";
          secretKeyFile = "/etc/hive/s3-secret-key";
          environmentFile = "/etc/website.env";
        };
        applications.bench3 = {
          project = inputs.website.packages.x86_64-linux.default;
          bucket = "s3://hive/bench3";
          endpoint = "http://zimaboard:9000";
          region = "auto";
          publicListen = "127.0.0.1:9110";
          internalListen = "127.0.0.1:9111";
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
        virtualHosts."bench1.yanpla.nl" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://127.0.0.1:9090";
        };
        virtualHosts."bench2.yanpla.nl" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://127.0.0.1:9100";
        };
        virtualHosts."bench3.yanpla.nl" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://127.0.0.1:9110";
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
