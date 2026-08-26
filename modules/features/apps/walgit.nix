{
  den.aspects.walgit.nixos =
    { inputs, pkgs, ... }:
    let
      # Upstream's pnpm dependency hash currently does not match its lockfile
      # with nixpkgs 26.05, so build the same web assets with the verified hash.
      walgitWeb = pkgs.stdenv.mkDerivation {
        pname = "walgit-web";
        version = "0.1.0";
        src = "${inputs.walgit}/web";
        pnpmDeps = pkgs.pnpm.fetchDeps {
          pname = "walgit-web";
          version = "0.1.0";
          src = "${inputs.walgit}/web";
          fetcherVersion = 2;
          hash = "sha256-+dpBjQZYeC7MPX4gtDUsyCSGAvBIrlD54pcXMjrjEUo=";
        };
        nativeBuildInputs = [
          pkgs.nodejs_24
          pkgs.pnpm.configHook
        ];
        buildPhase = ''
          runHook preBuild
          pnpm run build
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          cp -r dist "$out"
          runHook postInstall
        '';
      };
      walgit = inputs.walgit.packages.${pkgs.system}.walgit.overrideAttrs (_: {
        preConfigure = ''
          mkdir -p web
          cp -a ${walgitWeb} web/dist
        '';
      });
      walgitConfig = pkgs.writeText "walgit.toml" ''
        [server]
        listen = "127.0.0.1:8082"
        public_url = "https://git.yanpla.nl"
        auto_create_on_push = true
        roles = []

        [server.tls]
        mode = "off"

        [server.auth]
        mode = "token"
        anonymous_read = true
        tokens = [
          { principal = "admin", token = "", token_env = "WALGIT_TOKEN_ADMIN", write = true, admin = true },
        ]

        [store]
        backend = "s3"
        bucket = "walgit"

        [store.s3]
        endpoint = "http://127.0.0.1:8333"
        region = "us-east-1"
        access_key_env = "AWS_ACCESS_KEY_ID"
        secret_key_env = "AWS_SECRET_ACCESS_KEY"
        force_path_style = true

        [cache]
        dir = "/var/lib/walgit/cache"
        mode = "disk"
        disk_high_watermark = 0.9

        [maintenance]
        disk = "ssd"
      '';
    in
    {
      # One-node SeaweedFS deployment: master, volume, filer and its S3 gateway.
      # The S3 API is loopback-only and shares credentials with Walgit through
      # /etc/walgit.env, which is installed separately from this public repo.
      systemd.services.seaweedfs-walgit = {
        description = "SeaweedFS object store for Walgit";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          ExecStart = ''
            ${pkgs.seaweedfs}/bin/weed server \
              -dir=/var/lib/seaweedfs-walgit \
              -ip=127.0.0.1 \
              -ip.bind=127.0.0.1 \
              -master.port=9333 \
              -master.port.grpc=19333 \
              -volume.port=18080 \
              -volume.port.grpc=18081 \
              -filer \
              -filer.port=8888 \
              -filer.port.grpc=18888 \
              -s3 \
              -s3.port=8333 \
              -s3.ip.bind=127.0.0.1
          '';
          DynamicUser = true;
          StateDirectory = "seaweedfs-walgit";
          WorkingDirectory = "/var/lib/seaweedfs-walgit";
          EnvironmentFile = "/etc/walgit.env";
          Restart = "always";
          RestartSec = "5s";
        };
      };

      systemd.services.walgit = {
        description = "Walgit Git server";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "seaweedfs-walgit.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "seaweedfs-walgit.service" ];
        serviceConfig = {
          ExecStart = "${walgit}/bin/walgit serve --config ${walgitConfig}";
          DynamicUser = true;
          StateDirectory = "walgit";
          EnvironmentFile = "/etc/walgit.env";
          Restart = "always";
          RestartSec = "5s";
        };
      };

      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        virtualHosts."git.yanpla.nl" = {
          enableACME = true;
          forceSSL = true;
          extraConfig = ''
            client_max_body_size 0;
          '';
          locations."/" = {
            proxyPass = "http://127.0.0.1:8082";
            extraConfig = ''
              proxy_request_buffering off;
              proxy_read_timeout 3600s;
              proxy_send_timeout 3600s;
            '';
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
