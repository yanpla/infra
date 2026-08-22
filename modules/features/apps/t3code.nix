{
  # Headless t3code for remote agent access over the tailnet.
  # Runs as `yanpla` (admin.nix) so the in-app terminal shares his home dir.
  den.aspects.t3code.nixos =
    {
      inputs,
      pkgs,
      pkgs-unstable,
      ...
    }:
    let
      t3code-server = inputs.t3-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.t3code-server;
    in
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
          T3CODE_DISABLE_AUTO_UPDATE = "1";
        };
        path = with pkgs-unstable; [
          git
          gh
          tailscale # t3code shells out to `tailscale serve`
        ];
        serviceConfig = {
          User = "yanpla";
          Group = "users";
          StateDirectory = "t3code";
          WorkingDirectory = "/home/yanpla";
          ExecStart = "${t3code-server}/bin/t3 serve --host 0.0.0.0 --port 3773 --base-dir /var/lib/t3code --tailscale-serve /home/yanpla";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
}
