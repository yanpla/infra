{
  config,
  inputs,
  lib,
  self,
  ...
}:
let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs { inherit system; };
  pkgs-master = import inputs.nixpkgs-master {
    inherit system;
    config.allowUnfree = true;
  };
  specialArgs = { inherit inputs self pkgs-master; };

  hostModules = host: [
    config.hosts.${host}
    { networking.hostName = host; }
  ];
in
{
  # Each modules/hosts/<host>/configuration.nix sets hosts.<host>, importing
  # features from flake.modules.nixos by name.
  options.hosts = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = { };
    description = "NixOS configuration of each host, keyed by hostname.";
  };

  config.flake = {
    nixosConfigurations = lib.mapAttrs (
      host: _:
      lib.nixosSystem {
        inherit system specialArgs;
        modules = hostModules host;
      }
    ) config.hosts;

    colmenaHive = inputs.colmena.lib.makeHive (
      {
        meta = {
          nixpkgs = pkgs;
          inherit specialArgs;
        };
      }
      // lib.mapAttrs (host: _: {
        imports = hostModules host;
        deployment.targetHost = host;
        deployment.targetUser = if host == "tunneler" then "root" else "yanpla";
        deployment.privilegeEscalationCommand = [
          "sudo"
          "-n"
        ];
      }) config.hosts
    );
  };
}
