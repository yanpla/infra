{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  # Every file under modules/ is a module of this top-level eval. Files publish
  # NixOS modules under `modules.nixos.<name>`, and hosts under `hosts.<name>`
  # import them by name via the top-level `config`.
  options.modules.nixos = mkOption {
    type = types.lazyAttrsOf types.deferredModule;
    default = { };
    # A stable key lets the module system dedupe a feature imported twice.
    apply = lib.mapAttrs (
      name: module: {
        key = "modules.nixos.${name}";
        imports = [ module ];
      }
    );
    description = "Reusable NixOS modules, keyed by feature name.";
  };

  options.hosts = mkOption {
    type = types.lazyAttrsOf types.deferredModule;
    default = { };
    description = "NixOS configuration of each host, keyed by hostname.";
  };
}
