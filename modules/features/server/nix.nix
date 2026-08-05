{
  den.aspects.nix-settings.nixos =
    { config, lib, ... }:
    let
      # alpha is the only machine worth building on (16 threads, 30G). zimaboard
      # is the only machine builds are ever started from, so it is the only
      # client — beta and tunneler build for themselves and never offload.
      # Note alpha is also the box that hard-resets under compile load; the boost
      # cap in modules/hosts/alpha.nix is what makes it survive a full
      # calagopus-panel build. If builds start dying, look there.
      builder = "alpha";
      client = "zimaboard";

      isBuilder = config.networking.hostName == builder;
      isClient = config.networking.hostName == client;

      # Host-to-host auth reuses each machine's existing SSH host key, so no new
      # secret has to be provisioned or kept out of this repo. Only the public
      # halves live here.
      hostKeys = {
        alpha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATH4iTe7Q7vAB6zYSmMl4ueQN/Rd6jg57fqFl6kM6Sr root@alpha";
        zimaboard = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1fVUBovD8EimpQGVX8ZivvBVZzSAlr7MRoEVEOmk/e root@zimaboard";
      };
    in
    {
      nix = {
        settings = {
          experimental-features = "nix-command flakes";
          trusted-users = [
            "root"
            "yanpla"
          ];
          # Let the builder substitute from binary caches itself, instead of the
          # client downloading everything and copying it over the tailnet.
          builders-use-substitutes = true;
        };

        distributedBuilds = isClient;

        buildMachines = lib.optional isClient {
          hostName = builder; # tailnet MagicDNS name
          protocol = "ssh-ng";
          sshUser = "root";
          sshKey = "/etc/ssh/ssh_host_ed25519_key";
          systems = [ "x86_64-linux" ];
          maxJobs = 16;
          speedFactor = 4; # beats the local machine on any tie
          supportedFeatures = [
            "big-parallel" # the point of the exercise: rust/llvm builds
            "kvm"
            "nixos-test"
            "benchmark"
          ];
        };

        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
        optimise.automatic = true;
      };

      # The client needs alpha's host key up front: root's ssh runs
      # non-interactively and would otherwise refuse to connect.
      programs.ssh.knownHosts = lib.mkIf isClient {
        ${builder}.publicKey = hostKeys.${builder};
      };

      # Without keepalives, an alpha hard-reset mid-build leaves the remote-build
      # ssh connection hanging forever and the whole deploy just stops. This
      # makes it die in ~1min so nix reports a failure instead.
      programs.ssh.extraConfig = lib.mkIf isClient ''
        Host ${builder}
          ConnectTimeout 10
          ServerAliveInterval 15
          ServerAliveCountMax 4
      '';

      # Builder side: accept the client's host key as root. That is
      # root-equivalent access to alpha from zimaboard, which the admin keys in
      # admin.nix already grant from elsewhere.
      users.users.root.openssh.authorizedKeys.keys = lib.mkIf isBuilder [
        hostKeys.${client}
      ];
    };
}
