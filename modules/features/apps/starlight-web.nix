{
  den,
  lib,
  webapp,
  ...
}:
{
  # Serves starlight.allofus.dev: the Starlight-Web SvelteKit app with a
  # local PostgreSQL database and nginx + ACME TLS in front.
  den.aspects.starlight-web = {
    includes = [ den.aspects.web-proxy ];
    nixos =
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
        imports = [
          (webapp {
            name = "starlight-web";
            description = "Starlight web";
            domain = "starlight.yanpla.nl";
            port = 3000;
            exec = "${pkgs.nodejs}/bin/node ${pkg}/index.js";
            # Static user, not DynamicUser: postgres peer auth maps it to a role.
            user = "starlight-web";
            # Holds BETTER_AUTH_SECRET / DISCORD_CLIENT_ID / DISCORD_CLIENT_SECRET; create on the host:
            #   install -m 600 -o root <(printf 'BETTER_AUTH_SECRET=...\nDISCORD_CLIENT_ID=...\nDISCORD_CLIENT_SECRET=...\n') /etc/starlight-web.env
            environmentFile = "/etc/starlight-web.env";
          })
        ];

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

        systemd.services.starlight-web = {
          # mkAfter only to keep After= ordered as it was before this app moved
          # onto `webapp`; systemd treats the list as a set either way.
          after = lib.mkAfter [ "postgresql.service" ];
          requires = [ "postgresql.service" ];
          path = [ pkgs.nodejs ]; # drizzle-kit's bin stub does `exec node`
          environment = {
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
          serviceConfig.RuntimeDirectory = "starlight-web";
        };
      };
  };
}
