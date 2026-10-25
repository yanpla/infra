{
  # Calagopus DB Agent (github.com/calagopus/db-agent): provisions managed
  # databases in docker containers. calagopus-nix ships neither a package nor a
  # module for it, so we package the static release binary and wire up the
  # systemd unit that `calagopus-db-agent service-install` would generate.
  # Config is issued by the panel, not declared here: create a database agent
  # host in the panel and copy its generated YAML to /etc/calagopus-db-agent/config.yml.
  # The panel may push live config edits back into that file, so it stays mutable.
  flake.modules.nixos.calagopus-db-agent =
    { lib, pkgs, ... }:
    let
      version = "1.2.3";
      db-agent = pkgs.stdenvNoCC.mkDerivation {
        pname = "calagopus-db-agent";
        inherit version;
        src = pkgs.fetchurl {
          url = "https://github.com/calagopus/db-agent/releases/download/release-${version}/db-agent-x86_64-linux";
          hash = "sha256-BnFv5lt7jsXZEICVZtrc5kNhJM6UR7A8kr0aea7refE=";
        };
        dontUnpack = true;
        # Statically linked, so nothing to patch.
        installPhase = ''
          install -Dm755 $src $out/bin/calagopus-db-agent
        '';
        meta.mainProgram = "calagopus-db-agent";
      };

      # Database proxies bind the wings docker bridge gateway (172.18.0.1 on every
      # node), so game servers on the node can reach them and nothing public can.
      # Migrated nodes kept the pterodactyl network name.
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
        # The proxies bind the bridge gateway, which only exists once wings has
        # created its docker network.
        after = [
          "network-online.target"
          "docker.service"
          "calagopus-wings.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "docker.service" ];
        partOf = [ "docker.service" ];
        path = [ pkgs.kmod ]; # modprobes the tcp congestion control module
        startLimitIntervalSec = 180;
        startLimitBurst = 30;
        serviceConfig = {
          # Runs as root: drives the docker socket and chowns database data dirs.
          ExecStart = lib.getExe db-agent;
          KillMode = "process"; # leave database containers running across restarts
          LimitNOFILE = 4096;
          # Sockets bind-mounted into database containers; keep them across restarts.
          RuntimeDirectory = "calagopus-db-agent";
          RuntimeDirectoryMode = "0700";
          RuntimeDirectoryPreserve = true;
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      # Management API is tailnet-only, for the panel.
      networking.firewall.interfaces = lib.genAttrs wingsBridges (_: {
        allowedTCPPorts = databasePorts;
      }) // {
        "tailscale0".allowedTCPPorts = [ 8090 ];
      };
    };
}
