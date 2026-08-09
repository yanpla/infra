{
  # S3-compatible object storage for the tailnet. hive's control plane on beta
  # keeps everything it persists here, so this is the only stateful piece
  # behind yanpla.nl.
  den.aspects.rustfs.nixos =
    {
      inputs,
      pkgs-unstable,
      ...
    }:
    {
      # rustfs landed after the 26.05 branch-off: neither the package nor the
      # module exists in stable, so pull both from unstable.
      imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/web-servers/rustfs.nix" ];

      services.rustfs = {
        enable = true;
        package = pkgs-unstable.rustfs;
        # Access and secret key, out of the repo. Provision by hand:
        #   RUSTFS_ACCESS_KEY=... / RUSTFS_SECRET_KEY=...
        environmentFile = "/etc/rustfs.env";
        settings = {
          # On the SSD at /mnt/data, not the default /var/lib: zimaboard's root
          # is the 58G eMMC, which is both nearly full and the wrong medium for
          # a write-heavy object store.
          RUSTFS_VOLUMES = "/mnt/data/rustfs";
          # Reachable on the tailnet only; the firewall rule below is what
          # actually limits exposure.
          RUSTFS_ADDRESS = ":9000";
          RUSTFS_CONSOLE_ENABLE = "false";
        };
      };

      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9000 ];
    };
}
