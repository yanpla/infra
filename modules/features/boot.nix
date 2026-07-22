{
  den.aspects.systemd-boot.nixos = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };

  # GRUB on the removable path, with a BIOS boot partition as legacy fallback.
  den.aspects.grub-removable.nixos = {
    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
