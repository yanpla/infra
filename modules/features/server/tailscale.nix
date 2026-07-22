{
  # Deploys (colmena) reach the hosts over the tailnet.
  den.aspects.tailscale.nixos = {
    services.tailscale.enable = true;
  };
}
