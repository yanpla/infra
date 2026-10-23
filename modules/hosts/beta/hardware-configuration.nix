# Two disks, each: BIOS boot partition, RAID1 ESP and swap, and one half of
# a btrfs raid1 root.
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ehci_pci"
    "uhci_hcd"
    "hpsa"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "sr_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot.loader.grub.devices = [
    "/dev/sda"
    "/dev/sdb"
  ];

  boot.swraid = {
    # assembles the ESP/swap md RAID1 arrays in the initrd
    enable = true;
    mdadmConf = "MAILADDR root";
  };

  # Btrfs raid1 across both disks' root partitions; either label mounts it.
  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/disk-sdb-root";
    fsType = "btrfs";
    options = [
      "subvol=/root"
      "compress=zstd"
      "noatime"
    ];
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-partlabel/disk-sdb-root";
    fsType = "btrfs";
    options = [
      "subvol=/nix"
      "compress=zstd"
      "noatime"
    ];
  };
  # ESP mirrored as RAID1 metadata 1.0: the md superblock sits at the
  # partition's end, so UEFI still sees a plain vfat filesystem.
  fileSystems."/boot" = {
    device = "/dev/md/boot";
    fsType = "vfat";
  };

  swapDevices = [ { device = "/dev/md/swap"; } ];
  boot.resumeDevice = "/dev/md/swap";
}
