{ config, ... }:
let
  nixos = config.modules.nixos;
in
{
  modules.nixos.zimaboard-hardware =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        nixos.systemd-boot
        # zram spares the eMMC's limited write endurance; no on-disk swap.
        nixos.zram-swap
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "sd_mod"
        "sdhci_pci"
      ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.supportedFilesystems = [ "btrfs" ];
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      # Internal eMMC — holds boot and root.
      fileSystems."/" = {
        device = "/dev/disk/by-partlabel/disk-boot-root";
        fsType = "ext4";
      };
      fileSystems."/boot" = {
        device = "/dev/disk/by-partlabel/disk-boot-ESP";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      # Samsung 870 EVO 500GB — data disk.
      fileSystems."/mnt/data" = {
        device = "/dev/disk/by-partlabel/disk-data-data";
        fsType = "btrfs";
        options = [
          "compress=zstd"
          "noatime"
        ];
      };
    };
}
