{
  # S3-compatible object storage for hive assets. The API is reachable only
  # over Tailscale; credentials stay in /etc/rustfs.env outside the Nix store.
  den.aspects.rustfs.nixos =
    {
      lib,
      pkgs-unstable,
      ...
    }:
    {
      users.users.rustfs = {
        isSystemUser = true;
        group = "rustfs";
        home = "/mnt/data/rustfs";
      };
      users.groups.rustfs = { };

      systemd.tmpfiles.rules = [
        "d /mnt/data/rustfs 0750 rustfs rustfs -"
      ];

      systemd.services.rustfs = {
        description = "RustFS S3-compatible object storage";
        wantedBy = [ "multi-user.target" ];
        after = [
          "mnt-data.mount"
          "network-online.target"
        ];
        wants = [ "network-online.target" ];
        requires = [ "mnt-data.mount" ];

        environment = {
          RUSTFS_ADDRESS = "0.0.0.0:9000";
          RUSTFS_CONSOLE_ENABLE = "false";
          RUSTFS_VOLUMES = "/mnt/data/rustfs";
          RUST_LOG = "info";
        };

        serviceConfig = {
          ExecStart = lib.getExe pkgs-unstable.rustfs;
          EnvironmentFile = "/etc/rustfs.env";
          User = "rustfs";
          Group = "rustfs";
          Restart = "on-failure";
          RestartSec = "5s";

          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ "/mnt/data/rustfs" ];
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
        };
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9000 ];
    };
}
