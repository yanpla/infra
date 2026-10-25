{
  # Restic REST server holding Calagopus backups (server files and database
  # dumps), reached by wings nodes over the tailnet. The panel's "Zimaboard
  # restic" backup configuration points at rest:http://zimaboard.taila84e31.ts.net:8000/calagopus/.
  # Credentials are kept out of the nix store:
  #   <dataDir>/.htpasswd             bcrypt entry for the `calagopus` user (htpasswd -B)
  #   /etc/calagopus-restic.password  repository password, for the prune timer below
  flake.modules.nixos.calagopus-backups =
    { pkgs, ... }:
    let
      dataDir = "/mnt/data/restic";
      repository = "${dataDir}/calagopus";
    in
    {
      services.restic.server = {
        enable = true;
        inherit dataDir;
        listenAddress = "8000";
        privateRepos = true; # the calagopus user only sees /calagopus/
      };
      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8000 ];

      # Wings forgets snapshots when a backup is deleted but never prunes them (the
      # panel's prune jobs only dry-run for now), so reclaim the space here.
      systemd.services.calagopus-restic-prune = {
        description = "Prune the Calagopus restic repository";
        startAt = "Sun 04:00";
        environment = {
          RESTIC_REPOSITORY = repository;
          RESTIC_PASSWORD_FILE = "/etc/calagopus-restic.password";
          RESTIC_CACHE_DIR = "/var/cache/calagopus-restic-prune";
        };
        serviceConfig = {
          Type = "oneshot";
          User = "restic";
          CacheDirectory = "calagopus-restic-prune";
          # Waits out a backup that holds the lock instead of failing.
          ExecStart = "${pkgs.restic}/bin/restic prune --retry-lock 30m";
        };
      };
    };
}
