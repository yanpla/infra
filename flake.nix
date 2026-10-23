{
  description = "yanpla infra";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

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
    { self, ... }@inputs:
    let
      inherit (inputs) nixpkgs;
      inherit (nixpkgs) lib;

      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pkgs-master = import inputs.nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };

      # Every .nix file under modules/ is a top-level module; see modules/schema.nix.
      tree =
        (lib.evalModules {
          modules = lib.filter (lib.hasSuffix ".nix") (lib.filesystem.listFilesRecursive ./modules);
          specialArgs.inputs = inputs;
        }).config;

      servers = builtins.attrNames tree.hosts;

      serverModules = host: [
        tree.hosts.${host}
        { networking.hostName = host; }
      ];
    in
    {
      nixosConfigurations = lib.genAttrs servers (
        host:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs self pkgs-master; };
          modules = serverModules host;
        }
      );

      colmenaHive = inputs.colmena.lib.makeHive (
        {
          meta = {
            nixpkgs = pkgs;
            specialArgs = { inherit inputs self pkgs-master; };
          };
        }
        // lib.genAttrs servers (host: {
          imports = serverModules host;
          deployment.targetHost = host;
          deployment.targetUser = if host == "tunneler" then "root" else "yanpla";
          deployment.privilegeEscalationCommand = [
            "sudo"
            "-n"
          ];
        })
      );
    };
}
