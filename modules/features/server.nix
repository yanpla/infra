{ den, ... }:
{
  # Umbrella baseline every server includes; its members live in ./server/.
  # Hostname comes from the den host name via the battery.
  den.aspects.server.includes = [
    den.batteries.hostname
    den.aspects.nix-settings
    den.aspects.openssh
    den.aspects.tailscale
    den.aspects.admin-user
    den.aspects.git
    den.aspects.disko
  ];
}
