{
  # Serves music.yanpla.nl: the static Muzionnaire site built by its own
  # flake, handed straight to nginx with ACME TLS.
  den.aspects.muzionnaire.nixos =
    { inputs, pkgs, ... }:
    let
      site = inputs.muzionnaire.packages.${pkgs.system}.website;
    in
    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        virtualHosts."music.yanpla.nl" = {
          enableACME = true;
          forceSSL = true;
          root = site;
          locations."/".extraConfig = ''
            try_files $uri $uri/index.html $uri.html =404;
          '';
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
