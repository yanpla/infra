{
  # Full graphical desktop for remote access: KDE Plasma (Wayland) with SDDM
  # autologin keeps a live session running so Sunshine always has a desktop to
  # stream. Connect from Moonlight clients; pair via https://<host>:47990
  # (PIN flow) or mDNS discovery on the LAN. Works over LAN and tailnet alike.
  den.aspects.desktop.nixos =
    { pkgs, lib, ... }:
    {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      services.desktopManager.plasma6.enable = true;

      # Auto-login keeps the graphical session (and Sunshine) up after reboots,
      # even with no one at the machine.
      services.displayManager.autoLogin = {
        enable = true;
        user = "yanpla";
      };

      services.sunshine = {
        enable = true;
        # CAP_SYS_ADMIN on the wrapper binary so DRM/KMS capture works.
        capSysAdmin = true;
        openFirewall = true;
      };

      systemd.services.display-manager.wantedBy = [ "graphical.target" ];

      users.users.yanpla.extraGroups = [
        "input"
        "uinput"
      ];

      environment.systemPackages = [
        pkgs.kdePackages.krfb
      ];

      # krfb virtual monitor: exposes an extra 2560x1440 display
      systemd.user.services.krfb-virtualmonitor = {
        description = "krfb virtual monitor for Sunshine";
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = lib.concatStringsSep " " [
            "${pkgs.kdePackages.krfb}/bin/krfb-virtualmonitor"
            "--name Sunshine"
            "--resolution 2560x1440"
            "--password sunshine"
            "--port 5900"
          ];
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
}
