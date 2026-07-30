{
  # Headless t3code (github.com/pingdotgg/t3code) for remote agent access over the tailnet.
  # Runs as `yanpla` (admin.nix) so the in-app terminal shares his home dir.
  den.aspects.t3code.nixos =
    { pkgs-unstable, ... }:
    {
      # t3code drives `tailscale serve` itself and fetches its own tailnet cert,
      # both of which are root-gated unless `yanpla` is the operator.
      services.tailscale = {
        extraSetFlags = [ "--operator=yanpla" ];
        permitCertUid = "yanpla";
      };

      systemd.services.t3code = {
        description = "t3code web server";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "tailscaled.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "tailscaled.service" ];
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
          tailscale # t3code shells out to `tailscale serve`
        ];
        serviceConfig = {
          User = "yanpla";
          Group = "users";
          StateDirectory = "t3code";
          WorkingDirectory = "/home/yanpla";
          ExecStart = "${pkgs-unstable.nodejs}/bin/npx -y t3@0.0.31 serve --host 0.0.0.0 --port 3773 --tailscale-serve";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
}
