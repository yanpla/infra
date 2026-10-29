{ config, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  hosts.zimaboard = {
    imports = [
      ./hardware-configuration.nix
      nixos.default
      nixos.calagopus-backups
      nixos.monitoring
    ];
    system.stateVersion = "25.11";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # zram spares the eMMC's limited write endurance; no on-disk swap.
    zramSwap.enable = true;
  };
}
