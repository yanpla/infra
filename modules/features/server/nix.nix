{
  den.aspects.nix-settings.nixos.nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "yanpla"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise.automatic = true;
  };
}
