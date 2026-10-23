{
  # Serves yanpla.nl: the Astro SSR server from the website flake input,
  # fronted by nginx with ACME TLS.
  flake.modules.nixos.website =
    { inputs, pkgs, ... }:
    {
      systemd.services.website = {
        description = "yanpla.nl website";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          HOST = "127.0.0.1";
          PORT = "4321";
        };
        serviceConfig = {
          ExecStart = "${inputs.website.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/website";
          DynamicUser = true;
          Restart = "on-failure";
          RestartSec = "5s";
          # Holds GITHUB_TOKEN (lifts the API rate limit); create on the host:
          #   install -m 600 <(echo 'GITHUB_TOKEN=github_pat_...') /etc/website.env
          # Leading "-" lets the service start without it.
          EnvironmentFile = "-/etc/website.env";
        };
      };

      services.nginx.virtualHosts."yanpla.nl" = {
        # No www CNAME exists; add one before re-adding a www alias here.
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:4321";
      };
    };
}
