{
  den.aspects.disko.nixos =
    { inputs, ... }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      # Reusable disko fragments for the per-host disk layouts.
      _module.args.diskParts = {
        # UEFI system partition mounted on /boot.
        esp = size: {
          inherit size;
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };
        # Btrfs with /root and /nix subvolumes, zstd-compressed.
        btrfsRoot = {
          type = "btrfs";
          extraArgs = [ "-f" ];
          subvolumes = {
            "/root" = {
              mountpoint = "/";
              mountOptions = [
                "compress=zstd"
                "noatime"
              ];
            };
            "/nix" = {
              mountpoint = "/nix";
              mountOptions = [
                "compress=zstd"
                "noatime"
              ];
            };
          };
        };
      };
    };
}
