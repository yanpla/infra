{
  # Serves starlight.allofus.dev: the Starlight-Web SvelteKit app with a
  # local PostgreSQL database and nginx + ACME TLS in front.
  den.aspects.starlight-web.nixos =
    { inputs, pkgs, ... }:
    let
      pkg = inputs.starlight-web.packages.${pkgs.system}.starlight-web;
      src = inputs.starlight-web;
      # Peer auth over the unix socket (dir via PGHOST below): don't put the
      # socket path in the URL — postgres.js forwards unknown query params
      # as startup parameters, which postgres rejects.
      dbUrl = "postgres:///starlight-web";
    in
    {
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "starlight-web" ];
        ensureUsers = [
          {
            name = "starlight-web";
            ensureDBOwnership = true;
          }
        ];
      };

      # Static user, not DynamicUser: postgres peer auth maps it to a role.
      users.users.starlight-web = {
        isSystemUser = true;
        group = "starlight-web";
      };
      users.groups.starlight-web = { };

      systemd.services.starlight-web = {
        description = "Starlight web";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "postgresql.service"
        ];
        wants = [ "network-online.target" ];
        path = [ pkgs.nodejs ]; # drizzle-kit's bin stub does `exec node`
        requires = [ "postgresql.service" ];
        environment = {
          HOST = "127.0.0.1";
          PORT = "3000";
          ORIGIN = "https://starlight.yanpla.nl";
          PUBLIC_API_URL = "https://starlight.allofus.dev";
          DATABASE_URL = dbUrl;
          PGHOST = "/run/postgresql";
        };
        # drizzle-kit needs the repo layout next to node_modules; the build
        # output only ships node_modules, so stage both, then migrate.
        preStart = ''
          migrate="$RUNTIME_DIRECTORY/migrate"
          rm -rf "$migrate"
          cp -r ${src} "$migrate"
          chmod -R u+w "$migrate"
          ln -sfn ${pkg}/node_modules "$migrate/node_modules"
          cd "$migrate"
          ${pkg}/node_modules/.bin/drizzle-kit migrate
        '';
        serviceConfig = {
          ExecStart = "${pkgs.nodejs}/bin/node ${pkg}/index.js";
          User = "starlight-web";
          Group = "starlight-web";
          RuntimeDirectory = "starlight-web";
          Restart = "on-failure";
          RestartSec = "5s";
          # Holds BETTER_AUTH_SECRET / DISCORD_CLIENT_ID / DISCORD_CLIENT_SECRET; create on the host:
          #   install -m 600 -o root <(printf 'BETTER_AUTH_SECRET=...\nDISCORD_CLIENT_ID=...\nDISCORD_CLIENT_SECRET=...\n') /etc/starlight-web.env
          EnvironmentFile = "/etc/starlight-web.env";
        };
      };

      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        virtualHosts."starlight.yanpla.nl" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://127.0.0.1:3000";
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
