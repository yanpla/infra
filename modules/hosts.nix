{
  config,
  inputs,
  lib,
  ...
}:
let
  hostModules = host: module: [
    module
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
      host: module:
      lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = hostModules host module;
      }
    ) config.hosts;

    colmenaHive = inputs.colmena.lib.makeHive (
      {
        meta = {
          nixpkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          specialArgs = { inherit inputs; };
        };
      }
      // lib.mapAttrs (host: module: {
        imports = hostModules host module;
        deployment.targetHost = host;
        deployment.targetUser = "yanpla";
        deployment.privilegeEscalationCommand = [
          "sudo"
          "-n"
        ];
      }) config.hosts
    );
  };
}
