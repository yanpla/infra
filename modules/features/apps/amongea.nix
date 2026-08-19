{
  # nginx reverse proxy for amongea.yanpla.nl, fronting a service on
  # 127.0.0.1:10000 with ACME TLS.
  den.aspects.amongea.nixos = {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      virtualHosts."amongea.yanpla.nl" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:10000";
      };
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
