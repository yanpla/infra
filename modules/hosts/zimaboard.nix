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
          nil
          nixd
        ];

        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        programs.nix-ld.enable = true;

        fileSystems."/home/yanpla/Repos" = {
          device = "/mnt/data/repos";
          options = [ "bind" ];
        };

        system.stateVersion = "25.11";
      };
  };
}
