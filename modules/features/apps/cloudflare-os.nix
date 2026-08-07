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
      deployHiveWorker = pkgs.writeShellScript "cloudflare-os-hive-deploy" ''
        exec ${lib.getExe config.services.hive.package} \
          deploy ${cloudflareOs}/share/cloudflare-os/packages/workshop-backend \
          --route agents.yanpla.nl \
          --allow-outbound
      '';
    in
    {
      systemd.services.cloudflare-os-hive-deploy = {
        description = "Deploy Cloudflare OS as a stateful hive project";
        wantedBy = [ "multi-user.target" ];
        after = [ "hived.service" ];
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
