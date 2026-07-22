{
  # yanpla as passwordless-sudo admin, plus root ssh access with the same keys.
  den.aspects.admin-user.nixos =
    let
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVJA3E6FIAy52QV0fVvFeZUTTuHkJ+P+H8H39XSOLIw"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9ekaOOvAfWl/e4PCDfeP/kNwxabYlKGEnOv2zgu+vT"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINxhlht2mYoJDCW6aZP6mBy9PgiS881eFSW7NiIVE38b yanpl@yanplaptop"
      ];
    in
    {
      security.sudo.wheelNeedsPassword = false;

      users.users.root.openssh.authorizedKeys.keys = sshKeys;
      users.users.yanpla = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = sshKeys;
      };
    };
}
