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
      celld = pkgs.callPackage ../../../packages/celld.nix { };
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
      deployHiveWorker = pkgs.writeShellScript "cloudflare-os-hive-deploy" ''
        exec ${lib.getExe config.services.hive.package} \
          deploy ${cloudflareOs}/share/cloudflare-os/packages/workshop-backend \
          --route agents.yanpla.nl \
          --allow-outbound
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
        before = [ "hived.service" ];
        requiredBy = [ "hived.service" ];
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

      systemd.services.cloudflare-os-hive-deploy = {
        description = "Deploy Cloudflare OS as a stateful hive project";
        wantedBy = [ "multi-user.target" ];
        after = [
          "cloudflare-os-deploy.service"
          "hived.service"
        ];
        requires = [
          "hived.service"
        ];
        restartTriggers = [ cloudflareOs ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = deployHiveWorker;
          RemainAfterExit = true;
        };
      };
    };
}
