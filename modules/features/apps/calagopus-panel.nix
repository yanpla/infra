{ den, vhost, ... }:
{
  # Calagopus Panel (github.com/calagopus/panel): calagopus-nix ships its own
  # NixOS module plus an overlay providing pkgs.panel.
  den.aspects.calagopus-panel = {
    includes = [ den.aspects.web-proxy ];
    nixos =
      { inputs, ... }:
      {
        imports = [
          inputs.calagopus-nix.nixosModules.default
          # Vhost only: the unit comes from the module above.
          (vhost {
            domain = "panel.yanpla.nl";
            port = 8000;
            websockets = true; # panel uses websockets for live console
          })
        ];

        # The module's default `package = pkgs.panel` comes from this overlay.
        nixpkgs.overlays = [ inputs.calagopus-nix.overlays.default ];

        services.calagopus-panel = {
          enable = true;
          bind = "127.0.0.1"; # the web-proxy vhost is the public entrypoint
          port = 8000;
          trustedProxies = [
            # trust local nginx's X-Forwarded-* headers
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
      };
  };
}
