{
  # Host metrics for Prometheus, scraped over the tailnet only.
  flake.modules.nixos.node-exporter = {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
    };
    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9100 ];
  };
}
