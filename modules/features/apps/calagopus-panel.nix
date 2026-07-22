{
  # Calagopus Panel (github.com/calagopus/panel): calagopus-nix ships its own
  # NixOS module plus an overlay providing pkgs.panel.
  den.aspects.calagopus-panel.nixos =
    { inputs, ... }:
    {
      imports = [ inputs.calagopus-nix.nixosModules.default ];

      # The module's default `package = pkgs.panel` comes from this overlay.
      nixpkgs.overlays = [ inputs.calagopus-nix.overlays.default ];

      services.calagopus-panel = {
        enable = true;
        bind = "127.0.0.1"; # nginx below is the public entrypoint
        port = 8000;
        trustedProxies = [ # trust local nginx's X-Forwarded-* headers
          "127.0.0.1"
          "::1"
        ];
        # Holds APP_ENCRYPTION_KEY; kept out of the nix store:
        #   install -m 600 <(echo 'APP_ENCRYPTION_KEY=...') /etc/calagopus-panel.env
        environmentFile = "/etc/calagopus-panel.env";
        database.createLocally = true;
        redis.createLocally = true;
      };

      # Proxies wings traffic so wings' API can stay tailnet-only.
      systemd.services.calagopus-panel.environment.APP_ENABLE_WINGS_PROXY = "true";

      services.nginx = {
        enable = true;
        recommendedProxySettings = true; # sets X-Forwarded-For/-Proto/-Host
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        virtualHosts."panel.yanpla.nl" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8000";
            proxyWebsockets = true; # panel uses websockets for live console
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
