{ den, ... }:
{
  den.aspects.tunneler-hardware = {
    includes = [ den.aspects.grub-removable ];
    nixos =
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

        disko.devices = {
          disk.disk1 = {
            device = lib.mkDefault "/dev/vda";
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                boot = {
                  name = "boot";
                  size = "1M";
                  type = "EF02";
                };
                esp = {
                  name = "ESP";
                  size = "500M";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                  };
                };
                root = {
                  name = "root";
                  size = "100%";
                  content = {
                    type = "lvm_pv";
                    vg = "pool";
                  };
                };
              };
            };
          };
          lvm_vg.pool = {
            type = "lvm_vg";
            lvs.root = {
              size = "100%FREE";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "defaults" ];
              };
            };
          };
        };
      };
  };
}
