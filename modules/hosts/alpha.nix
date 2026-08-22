{
  den,
  pkgs,
  inputs,
  system,
  ...
}:
{
  den.aspects.alpha = {
    includes = [
      den.aspects.server
      den.aspects.alpha-hardware
      den.aspects.zram-swap
      den.aspects.calagopus-wings
      den.aspects.desktop
      den.aspects.t3code
    ];

    nixos =
      { pkgs, pkgs-unstable, ... }:
      let
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
        system.stateVersion = "25.11";

        # Run prebuilt/FHS binaries (e.g. Delta)
        programs.nix-ld = {
          enable = true;
          libraries = with pkgs; [
            glibc
            libGL
            vulkan-loader
            wayland
            libxkbcommon # delta bundles its own copy which expects /usr/share/X11/xkb
            xorg.libX11
            xorg.libxcb
          ];
        };

        environment.systemPackages = with pkgs-unstable; [
          zed-editor
          # Delta looks for a "zed" CLI; nixpkgs renames it to "zeditor"
          (pkgs.runCommand "zed-cli-alias" { } ''
            mkdir -p $out/bin
            ln -s ${zed-editor}/bin/zeditor $out/bin/zed
          '')
          nil
          nixd
          claude-code
          codex
          pi-coding-agent
          gh
          inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

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
  };
}
