{ den, ... }:
{
  den.aspects.zimaboard = {
    includes = [
      den.aspects.default
      den.aspects.zimaboard-hardware
    ];
    nixos.system.stateVersion = "25.11";
  };
}
