{
  # Cua Driver (github:trycua/cua): computer-use MCP for agents. The daemon runs
  # inside the Plasma session so it inherits the Wayland/portal env; agents
  # outside it (t3code) attach with `cua-driver mcp --socket <sock>`.
  den.aspects.cua-driver.nixos =
    { inputs, pkgs, ... }:
    let
      cua-driver = inputs.cua.packages.${pkgs.stdenv.hostPlatform.system}.cua-driver;
    in
    {
      imports = [ inputs.cua.nixosModules.cua-driver ];

      services.cua-driver = {
        enable = true;
        package = cua-driver;
      };

      environment.variables.DO_NOT_TRACK = "1";

      # KDE input/capture go through the RemoteDesktop portal: approve its
      # prompt once (with "allow restoring") after the daemon first starts.
      systemd.user.services.cua-driver = {
        description = "Cua Driver daemon";
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        path = [ "/run/current-system/sw" ];
        environment = {
          DO_NOT_TRACK = "1";
          CUA_DRIVER_RS_ENABLE_WAYLAND = "1";
        };
        serviceConfig = {
          ExecStart = "${cua-driver}/bin/cua-driver serve --socket %h/.cache/cua-driver/cua-driver.sock";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
}
