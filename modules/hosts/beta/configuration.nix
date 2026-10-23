{ config, inputs, ... }:
let
  nixos = config.flake.modules.nixos;
  net = inputs.infra-private.hostNetworking.beta;
in
{
  hosts.beta =
    let
      grokbotKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsbsGrkT0zrAUTcjWoQTeIru8OUoIuAmO2sfQl18kgV";
    in
    {
      imports = [
        ./hardware-configuration.nix
        nixos.default
        nixos.website
        nixos.starlight-web
        nixos.muzionnaire
        nixos.calagopus-panel
        nixos.calagopus-wings
        nixos.smokeping
      ];

      users.users.rooq = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [ grokbotKey ];
      };
      users.users.root.openssh.authorizedKeys.keys = [ grokbotKey ];

      # No DHCP on this network
      networking.useDHCP = false;
      systemd.network = {
        enable = true;
        networks."10-wan" = {
          matchConfig.MACAddress = net.mac;
          address = [ "${net.address}/${toString net.prefixLength}" ];
          routes = [
            {
              Gateway = net.gateway;
              GatewayOnLink = true;
            }
          ];
          networkConfig.DNS = [
            "1.1.1.1"
            "8.8.8.8"
          ];
          linkConfig.RequiredForOnline = "routable";
        };
      };
      networking.nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];

      system.stateVersion = "26.05";

      # GRUB on the removable EFI path, with a BIOS boot partition as legacy fallback.
      boot.loader.grub = {
        efiSupport = true;
        efiInstallAsRemovable = true;
      };

      # Shared front door for the web apps above; each app only declares its vhost.
      services.nginx = {
        enable = true;
        recommendedProxySettings = true; # sets X-Forwarded-For/-Proto/-Host
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
      };
      security.acme = {
        acceptTerms = true;
        defaults.email = "me@yanpla.nl";
      };
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
