{ lib, ... }:
let
  # A TLS vhost proxying one public name to a local port. Split out from
  # `webapp` so an app whose unit comes from its own NixOS module can still
  # get the ingress half.
  mkVhost =
    {
      domain,
      port,
      host ? "127.0.0.1",
      # Set for apps whose clients hold a socket open (live consoles, HMR).
      websockets ? false,
    }:
    {
      services.nginx.virtualHosts.${domain} = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${host}:${toString port}";
        }
        // lib.optionalAttrs websockets { proxyWebsockets = true; };
      };
    };
in
{
  # How this repo serves HTTP apps, in one place. Two halves:
  #
  #  * the `web-proxy` aspect: nginx, ACME and the public ports, which every
  #    app-serving host needs exactly once regardless of how many apps it runs.
  #  * the `webapp`/`vhost` helpers: per-app boilerplate — a TLS vhost proxying
  #    to a loopback port, and the systemd unit behind it.
  #
  # An app aspect includes `web-proxy` and calls `webapp`; anything unusual it
  # needs (a database, a migration step, extra environment) is ordinary NixOS
  # config merged alongside, so the helper never has to grow a knob for it.
  #
  # These are plain functions rather than aspects because aspects are functions
  # of *context* (host/user), not of arbitrary arguments. Exposing them through
  # `_module.args` makes them available to every module in the den eval.
  #
  # Both return a module whose top-level attribute names are fixed. Deciding a
  # key from an argument that reaches into `pkgs` (an `exec` path, say) makes
  # the module's shape depend on its own arguments, which is an infinite
  # recursion — that is why `exec` is mandatory here instead of optional.
  _module.args.vhost = mkVhost;

  _module.args.webapp =
    {
      name,
      domain,
      port,
      exec,
      host ? "127.0.0.1",
      websockets ? false,
      description ? name,
      # A static user gets created below; the default is a DynamicUser, which
      # suits an app that only ever touches its own state directory.
      user ? null,
      # Verbatim, so a caller can mark it optional with a leading "-".
      environmentFile ? null,
    }:
    mkVhost {
      inherit
        domain
        port
        host
        websockets
        ;
    }
    // {
      systemd.services.${name} = {
        inherit description;
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          HOST = host;
          PORT = toString port;
        };
        serviceConfig = {
          ExecStart = exec;
          Restart = "on-failure";
          RestartSec = "5s";
        }
        // (
          if user == null then
            { DynamicUser = true; }
          else
            {
              User = user;
              Group = user;
            }
        )
        // lib.optionalAttrs (environmentFile != null) { EnvironmentFile = environmentFile; };
      };
    }
    // lib.optionalAttrs (user != null) {
      users.users.${user} = {
        isSystemUser = true;
        group = user;
      };
      users.groups.${user} = { };
    };

  den.aspects.web-proxy.nixos = {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true; # sets X-Forwarded-For/-Proto/-Host
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
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
