{ den, ... }:
{
  den.aspects.alpha = {
    includes = [
      den.aspects.server
      den.aspects.alpha-hardware
      den.aspects.zram-swap
      den.aspects.calagopus-wings
    ];
    nixos.system.stateVersion = "25.11";
  };
}
