{ config, ... }:
let
  nixos = config.modules.nixos;
in
{
  hosts.zimaboard = {
    imports = [
      ./hardware-configuration.nix
      nixos.default
      nixos.systemd-boot
      # zram spares the eMMC's limited write endurance; no on-disk swap.
      nixos.zram-swap
    ];
    system.stateVersion = "25.11";
  };
}
