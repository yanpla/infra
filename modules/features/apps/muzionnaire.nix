{
  # Serves music.yanpla.nl: the static Muzionnaire site built by its own
  # flake, handed straight to nginx with ACME TLS.
  flake.modules.nixos.muzionnaire =
    { inputs, pkgs, ... }:
    let
      site = inputs.muzionnaire.packages.${pkgs.stdenv.hostPlatform.system}.website;
    in
    {
      services.nginx.virtualHosts."music.yanpla.nl" = {
        enableACME = true;
        forceSSL = true;
        root = site;
        locations."/".extraConfig = ''
          try_files $uri $uri/index.html $uri.html =404;
        '';
      };
    };
}
