{ den, webapp, ... }:
{
  # Serves yanpla.nl: the Astro SSR server from the website flake input,
  # fronted by nginx with ACME TLS.
  den.aspects.website = {
    includes = [ den.aspects.web-proxy ];
    nixos =
      { inputs, pkgs, ... }:
      webapp {
        name = "website";
        description = "yanpla.nl website";
        # No www CNAME exists; add one before re-adding a www alias here.
        domain = "yanpla.nl";
        port = 4321;
        exec = "${inputs.website.packages.${pkgs.system}.default}/bin/website";
        # Holds GITHUB_TOKEN (lifts the API rate limit); create on the host:
        #   install -m 600 <(echo 'GITHUB_TOKEN=github_pat_...') /etc/website.env
        # Leading "-" lets the service start without it.
        environmentFile = "-/etc/website.env";
      };
  };
}
