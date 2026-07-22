{
  # Headless t3code (github.com/pingdotgg/t3code) for remote agent access over the tailnet.
  # Runs as `yanpla` (admin.nix) so the in-app terminal shares his home dir.
  den.aspects.t3code.nixos =
    { pkgs-unstable, ... }:
    {
      systemd.services.t3code = {
        description = "t3code web server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          T3CODE_HOME = "/var/lib/t3code";
        };
        path = with pkgs-unstable; [
          nodejs
          claude-code
          bash # node-pty compiles via node-gyp on first `npx` fetch
          gnumake
          gcc
          python3
          git
          gh
        ];
        serviceConfig = {
          User = "yanpla";
          Group = "users";
          StateDirectory = "t3code";
          WorkingDirectory = "/home/yanpla";
          # npx caches under $HOME (T3CODE_HOME), so updates land on restart.
          ExecStart = "${pkgs-unstable.nodejs}/bin/npx -y t3@nightly serve --host 0.0.0.0 --port 3773";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
}
