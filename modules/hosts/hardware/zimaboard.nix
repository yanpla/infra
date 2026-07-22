{ den, ... }:
{
  den.aspects.zimaboard-hardware = {
    includes = [
      den.aspects.systemd-boot
      # zram spares the eMMC's limited write endurance; no on-disk swap.
      den.aspects.zram-swap
    ];
    nixos =
      {
        config,
        lib,
        modulesPath,
        diskParts,
        ...
      }:
      {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

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

        disko.devices.disk = {
          # Internal eMMC — holds boot and root.
          boot = {
            type = "disk";
            device = "/dev/disk/by-id/mmc-Biwin_0x4e8d119c";
            content = {
              type = "gpt";
              partitions = {
                ESP = diskParts.esp "512M";
                root = {
                  size = "100%";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                  };
                };
              };
            };
          };

          # Samsung 870 EVO 500GB — data disk.
          data = {
            type = "disk";
            device = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNL0Y808420R";
            content = {
              type = "gpt";
              partitions.data = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  mountpoint = "/mnt/data";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
  };
}
