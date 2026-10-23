{
  description = "yanpla infra";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";

    website.url = "git+ssh://git@github.com/yanpla/website";
    website.inputs.nixpkgs.follows = "nixpkgs";

    starlight-web.url = "git+ssh://git@github.com/All-Of-Us-Mods/Starlight-Web?ref=original";
    starlight-web.inputs.nixpkgs.follows = "nixpkgs";

    muzionnaire.url = "git+ssh://git@github.com/yanpla/muzionnaire";
    muzionnaire.inputs.nixpkgs.follows = "nixpkgs";

    infra-private.url = "git+ssh://git@github.com/yanpla/infra-private";

    # No nixpkgs follows: keeps hashes matching upstream CI, so cachix hits.
    calagopus-nix.url = "github:calagopus/nix";

    helium.url = "github:AlvaroParker/helium-nix";
    helium.inputs.nixpkgs.follows = "nixpkgs";

    t3-code-nix.url = "github:LisaScheers/t3-code-nix";
    t3-code-nix.inputs.nixpkgs.follows = "nixpkgs-master";
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;

      # Every .nix file under modules/ is a flake-parts module, except each host's
      # hardware-configuration.nix, which its configuration.nix imports by path.
      isFlakeModule = path: lib.hasSuffix ".nix" path && baseNameOf path != "hardware-configuration.nix";
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.modules
      ]
      ++ lib.filter isFlakeModule (lib.filesystem.listFilesRecursive ./modules);

      systems = [ "x86_64-linux" ];
    };
}
