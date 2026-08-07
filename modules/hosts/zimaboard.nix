{ den, ... }:
{
  den.aspects.zimaboard = {
    includes = [
      den.aspects.server
      den.aspects.zimaboard-hardware
      den.aspects.t3code
    ];
    nixos =
      { pkgs-unstable, ... }:
      {
        environment.systemPackages = with pkgs-unstable; [
          claude-code
          codex
          opencode
          nil
          nixd
        ];

        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        programs.nix-ld.enable = true;

        system.stateVersion = "25.11";
      };
  };
}
