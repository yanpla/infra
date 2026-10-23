{ lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot.loader.grub.devices = [ "/dev/vda" ];

  # ext4 root on LVM (vg "pool").
  fileSystems."/" = {
    device = "/dev/pool/root";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/disk-disk1-ESP";
    fsType = "vfat";
  };
}
