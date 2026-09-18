{
  den.aspects.default.nixos =
  let
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVJA3E6FIAy52QV0fVvFeZUTTuHkJ+P+H8H39XSOLIw"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9ekaOOvAfWl/e4PCDfeP/kNwxabYlKGEnOv2zgu+vT"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINxhlht2mYoJDCW6aZP6mBy9PgiS881eFSW7NiIVE38b yanpl@yanplaptop"
    ];
  in
  {
    users.users.root.openssh.authorizedKeys.keys = sshKeys;
    users.users.yanpla = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = sshKeys;
    };

    services.openssh = {
      enable = true;
      openFirewall = false;
    };

    services.tailscale.enable = true;

    security.sudo.wheelNeedsPassword = false;

    nix = {
      settings.experimental-features = [ "nix-command" "flakes" ];
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
      optimise.automatic = true;
    };

    programs.git = {
      enable = true;
      config = {
        user = {
          name = "yanpla";
          email = "me@yanpla.nl";
        };
        init.defaultBranch = "main";
      };
    };
  };
}
