{
  # Calagopus Wings (github.com/calagopus/wings): calagopus-nix ships no NixOS
  # module for it, so we wire up the systemd service ourselves.
  # Config is issued by the panel, not declared here: create a node in the
  # panel UI and copy its generated YAML to /etc/calagopus/config.yml.
  den.aspects.calagopus-wings.nixos =
    { inputs, lib, pkgs, ... }:
    let
      wings = inputs.calagopus-nix.packages.${pkgs.system}.wings;
      configFile = "/etc/calagopus/config.yml";
    in
    {
      systemd.services.calagopus-wings = {
        description = "Calagopus Wings";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "docker.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "docker.service" ];
        serviceConfig = {
          # Runs as root: manages containers and binds privileged mounts.
          ExecStart = "${lib.getExe wings} --config ${configFile}";
          StateDirectory = "calagopus-wings";
          WorkingDirectory = "/var/lib/calagopus-wings";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      # Game-server runner user (config `system.username`, default "pterodactyl").
      # Declared here since wings would otherwise shell out to `useradd`.
      users.groups.pterodactyl = { };
      users.users.pterodactyl = {
        isSystemUser = true;
        group = "pterodactyl";
        description = "Calagopus wings server runner";
      };

      virtualisation.docker.enable = true; # wings drives containers over the docker socket

      # SFTP is public; the HTTP API is tailnet-only so a remote panel can still reach it.
      networking.firewall.allowedTCPPorts = [
        2022
      ];
      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
        8080
      ];
    };
}
