{ config, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  hosts.zimaboard = {
    imports = [
      ./hardware-configuration.nix
      nixos.default
    ];
    system.stateVersion = "25.11";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
