{
  # Full graphical desktop for remote access: KDE Plasma (Wayland) with SDDM
  # autologin keeps a live session running so Sunshine always has a desktop to
  # stream. Connect from Moonlight clients; pair via https://<host>:47990
  # (PIN flow) or mDNS discovery on the LAN. Works over LAN and tailnet alike.
  den.aspects.desktop.nixos =
    { pkgs, ... }:
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
    };
}
