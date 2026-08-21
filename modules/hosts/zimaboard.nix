{ den, ... }:
{
  den.aspects.zimaboard = {
    includes = [
      den.aspects.server
      den.aspects.zimaboard-hardware
    ];
    nixos.system.stateVersion = "25.11";
  };
}
