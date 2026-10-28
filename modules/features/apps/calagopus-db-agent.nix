{
  # Calagopus DB Agent. Config comes from the panel: copy its YAML to
  # /etc/calagopus-db-agent/config.yml (kept mutable, the panel writes to it).
  flake.modules.nixos.calagopus-db-agent =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      db-agent = inputs.calagopus-nix.packages.${pkgs.stdenv.hostPlatform.system}.db-agent;

      # Database proxies listen on the wings docker bridge gateway.
      wingsBridges = [
        "pterodactyl_nw"
        "calagopus_nw"
      ];
      databasePorts = [
        5432 # postgres
        3306 # mariadb
        27017 # mongodb
        6379 # redis
      ];
    in
    {
      environment.systemPackages = [ db-agent ];

      systemd.services.calagopus-db-agent = {
        description = "Calagopus DB Agent";
        wantedBy = [ "multi-user.target" ];
        # Wings creates the bridge network the proxies bind to.
        after = [
          "network-online.target"
          "docker.service"
          "calagopus-wings.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "docker.service" ];
        partOf = [ "docker.service" ];
        path = [ pkgs.kmod ];
        startLimitIntervalSec = 180;
        startLimitBurst = 30;
        serviceConfig = {
          ExecStart = lib.getExe db-agent;
          KillMode = "process"; # keep database containers running across restarts
          LimitNOFILE = 4096;
          RuntimeDirectory = "calagopus-db-agent";
          RuntimeDirectoryMode = "0700";
          RuntimeDirectoryPreserve = true;
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      networking.firewall.interfaces = lib.genAttrs wingsBridges (_: {
        allowedTCPPorts = databasePorts;
      }) // {
        "tailscale0".allowedTCPPorts = [ 8090 ];
      };
    };
}
