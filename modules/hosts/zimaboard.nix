{ config, ... }:
let
  nixos = config.modules.nixos;
in
{
  hosts.zimaboard = {
    imports = [
      nixos.default
      nixos.zimaboard-hardware
    ];
    system.stateVersion = "25.11";
  };
}
