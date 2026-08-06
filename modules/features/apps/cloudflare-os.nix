{
  den.aspects.cloudflare-os.nixos =
    {
      config,
      lib,
      pkgs,
      pkgs-unstable,
      ...
    }:
    let
      cloudflareOs = pkgs-unstable.callPackage ../../../packages/cloudflare-os.nix { };
      hiveWorker = pkgs.runCommand "cloudflare-os-hive-worker" { } ''
        cp -r ${../../../packages/cloudflare-os-hive-worker} $out
      '';
      celld = pkgs.stdenvNoCC.mkDerivation {
        pname = "celld";
        version = "0.1.0";
        src = pkgs.fetchurl {
          url = "https://github.com/denoland/celld/releases/download/v0.1.0/celld-x86_64-unknown-linux-gnu.gz";
          hash = "sha256-E5NUwoYY/mSIZFmPXN9prpGhdrMrkEGKgT4Cboa+mnw=";
        };
        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.gzip
        ];
        buildInputs = [ pkgs.stdenv.cc.cc.lib ];
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/bin
          gzip -dc $src > $out/bin/celld
          chmod 0555 $out/bin/celld
        '';
        meta.mainProgram = "celld";
      };
      withCredentials =
        name: command:
        pkgs.writeShellScript name ''
          set -eu
          export AWS_ACCESS_KEY_ID="$(cat "$CREDENTIALS_DIRECTORY/access-key")"
          export AWS_SECRET_ACCESS_KEY="$(cat "$CREDENTIALS_DIRECTORY/secret-key")"
          export AWS_REGION=us-east-1
          export S3_ENDPOINT=http://zimaboard:9000
          export CELLD_BUCKET=s3://hive-cloudflare-os
          ${command}
        '';
      deploy = withCredentials "cloudflare-os-deploy" ''
        export CELLD_ESBUILD=${lib.getExe pkgs-unstable.esbuild}
        exec ${lib.getExe celld} deploy \
          ${cloudflareOs}/share/cloudflare-os/packages/workshop-backend
      '';
      run = withCredentials "cloudflare-os-run" ''
        export CELLD_WORKER_LOADER=LOADER
        export CELLD_WATCH=/var/lib/cloudflare-os/cells
        export CELLD_ASSET_CACHE_DIR=/var/cache/cloudflare-os/assets
        exec ${lib.getExe celld} \
          --listen 127.0.0.1:9180
      '';
      deployHiveWorker = pkgs.writeShellScript "cloudflare-os-hive-deploy" ''
        exec ${lib.getExe config.services.hive.package} \
          deploy ${hiveWorker} --no-bundle
      '';
      credentials = [
        "access-key:/etc/cloudflare-os-s3-access-key"
        "secret-key:/etc/cloudflare-os-s3-secret-key"
      ];
    in
    {
      users.users.cloudflare-os = {
        isSystemUser = true;
        group = "cloudflare-os";
      };
      users.groups.cloudflare-os = { };

      systemd.services.cloudflare-os-deploy = {
        description = "Deploy Cloudflare OS to its celld fleet";
        before = [ "cloudflare-os.service" ];
        requiredBy = [ "cloudflare-os.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = deploy;
          User = "cloudflare-os";
          Group = "cloudflare-os";
          LoadCredential = credentials;
          StateDirectory = "cloudflare-os";
          CacheDirectory = "cloudflare-os";
        };
      };

      systemd.services.cloudflare-os = {
        description = "Cloudflare OS Durable Object runtime";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "cloudflare-os-deploy.service"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          ExecStart = run;
          Restart = "on-failure";
          RestartSec = "5s";
          User = "cloudflare-os";
          Group = "cloudflare-os";
          LoadCredential = credentials;
          StateDirectory = "cloudflare-os";
          CacheDirectory = "cloudflare-os";
          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
        };
      };

      systemd.services.cloudflare-os-hive-deploy = {
        description = "Route Cloudflare OS through hive";
        wantedBy = [ "multi-user.target" ];
        after = [
          "cloudflare-os.service"
          "hived.service"
        ];
        requires = [
          "cloudflare-os.service"
          "hived.service"
        ];
        restartTriggers = [ hiveWorker ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = deployHiveWorker;
          RemainAfterExit = true;
        };
      };
    };
}
