{ den, ... }:
{
  den.aspects.alpha-hardware = {
    includes = [ den.aspects.systemd-boot ];
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
          "nvme"
          "ahci"
          "xhci_pci"
          "usb_storage"
          "usbhid"
          "sd_mod"
        ];
        boot.kernelModules = [ "kvm-amd" ];
        hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

        disko.devices.disk.main = {
          type = "disk";
          # Samsung 980 PRO 1TB — the only disk in alpha.
          device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNF1WA43433K";
          content = {
            type = "gpt";
            partitions = {
              ESP = diskParts.esp "1G";
              root = {
                size = "100%";
                content = diskParts.btrfsRoot;
              };
            };
          };
        };
      };
  };
}
