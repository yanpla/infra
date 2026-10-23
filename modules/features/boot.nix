{
  modules.nixos.systemd-boot = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };

  # GRUB on the removable path, with a BIOS boot partition as legacy fallback.
  modules.nixos.grub-removable = {
    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
