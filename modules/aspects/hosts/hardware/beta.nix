{ den, ... }:
let
  # Same partition table on both disks: BIOS boot, RAID1 ESP/swap, btrfs raid1 root.
  betaDisk = device: rootContent: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        boot = { # BIOS boot partition, for legacy GRUB
          name = "boot";
          size = "1M";
          type = "EF02";
        };
        # ESP mirrored as RAID1 metadata 1.0: the md superblock sits at the
        # partition's end, so UEFI still sees a plain vfat filesystem.
        esp = {
          name = "ESP";
          size = "1G";
          type = "EF00";
          content = {
            type = "mdraid";
            name = "boot";
          };
        };
        swap = {
          name = "swap";
          size = "8G";
          content = {
            type = "mdraid";
            name = "swap";
          };
        };
        root = {
          name = "root";
          size = "100%";
        }
        // rootContent;
      };
    };
  };
in
{
  den.aspects.beta-hardware = {
    includes = [ den.aspects.grub-removable ];
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

        boot.swraid = { # assembles the ESP/swap md RAID1 arrays in the initrd
          enable = true;
          mdadmConf = "MAILADDR root";
        };

        disko.devices = {
          disk = {
            sda = betaDisk "/dev/sda" { }; # disko processes disks alphabetically; sdb creates the fs
            # mkfs.btrfs is given both root partitions, creating raid1 data+metadata.
            sdb = betaDisk "/dev/sdb" {
              content = diskParts.btrfsRoot // {
                extraArgs = [
                  "-f"
                  "-d"
                  "raid1"
                  "-m"
                  "raid1"
                  "/dev/disk/by-partlabel/disk-sda-root"
                ];
              };
            };
          };

          mdadm = {
            boot = {
              type = "mdadm";
              level = 1;
              metadata = "1.0";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              type = "mdadm";
              level = 1;
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
          };
        };
      };
  };
}
