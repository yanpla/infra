{ config, inputs, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  hosts.alpha =
    { pkgs, ... }:
    let
      pkgs-master = import inputs.nixpkgs-master {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };

      maxKHz = 4800000;

      capBoost = pkgs.writeShellScript "cap-cpu-boost" ''
        set -eu
        applied=0
        for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
          [ -w "$f" ] || continue
          echo ${toString maxKHz} > "$f"
          applied=$((applied + 1))
        done
        echo "capped scaling_max_freq to ${toString maxKHz} kHz on $applied cpus"
      '';
    in
    {
      imports = [
        ./hardware-configuration.nix
        nixos.default
        nixos.calagopus-wings
        nixos.desktop
        nixos.t3code
      ];

      system.stateVersion = "25.11";

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      environment.systemPackages = with pkgs-master; [
        zed-editor
        nil
        nixd
        claude-code
        codex
        pi-coding-agent
        vinegar
        gh
        inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      programs.direnv.enable = true;
      programs.nix-ld.enable = true;

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };

      nixpkgs.config.allowUnfree = true;

      systemd.services.cap-cpu-boost = {
        description = "Cap CPU boost clock (workaround for hard resets at stock boost)";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = capBoost.outPath;
        };
      };
    };
}
