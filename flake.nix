{
  description = "yanpla infra";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    website.url = "git+ssh://git@github.com/yanpla/website";
    website.inputs.nixpkgs.follows = "nixpkgs";

    starlight-web.url = "git+ssh://git@github.com/All-Of-Us-Mods/Starlight-Web";
    starlight-web.inputs.nixpkgs.follows = "nixpkgs";

    infra-private.url = "git+ssh://git@github.com/yanpla/infra-private";

    den.url = "github:denful/den";
    import-tree.url = "github:denful/import-tree";

    calagopus-nix.url = "github:Saturn745/calagopus-nix";
    calagopus-nix.inputs.nixpkgs.follows = "nixpkgs";

    helium.url = "github:AlvaroParker/helium-nix";
    helium.inputs.nixpkgs.follows = "nixpkgs";

    t3-code-nix.url = "github:LisaScheers/t3-code-nix";
    t3-code-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs =
    { self, ... }@inputs:
    let
      inherit (inputs) nixpkgs;
      inherit (nixpkgs) lib;

      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      # Hosts/aspects are declared in modules/den.nix; each host exposes a mainModule pulling in its aspects.
      den =
        (lib.evalModules {
          modules = [ (inputs.import-tree ./modules) ];
          specialArgs.inputs = inputs;
        }).config;

      denHosts = den.den.hosts.x86_64-linux;
      servers = builtins.attrNames denHosts;

      serverModules = host: [ denHosts.${host}.mainModule ];
    in
    {
      nixosConfigurations = lib.genAttrs servers (
        host:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs self pkgs-unstable; };
          modules = serverModules host;
        }
      );

      colmenaHive = inputs.colmena.lib.makeHive (
        {
          meta = {
            nixpkgs = pkgs;
            specialArgs = { inherit inputs self pkgs-unstable; };
          };
        }
        // lib.genAttrs servers (host: {
          imports = serverModules host;
          deployment.targetHost = host;
          deployment.targetUser = "yanpla";
          deployment.privilegeEscalationCommand = [
            "sudo"
            "-n"
          ];
        })
      );
    };
}
