{
  inputs.haskellNix.url = "github:input-output-hk/haskell.nix";
  inputs.nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, haskellNix }:
    let
      supportedSystems = [
        "x86_64-linux"
      ];
    in
      flake-utils.lib.eachSystem supportedSystems (system:
      let
        overlays =
          [ haskellNix.overlay
              (final: prev: {
                hixProject =
                  final.haskell-nix.project {
                    src = ./.;
                    compiler-nix-name = "ghc90";
                    evalSystem = "x86_64-linux";
                  };
                }
              )
          ];
        pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
        flake = pkgs.hixProject.flake {};
      in flake // rec
           { legacyPackages = pkgs;
              packages =  
                { examples = flake.packages."straw:test:examples";
                  lib = flake.packages."straw:lib:straw";
                  all = pkgs.symlinkJoin {
                    name = "all";
                    paths = with packages;
                      [ lib
                        examples
                      ];
                  };
                  default = packages.all;
                };
             devShells =
               { default =
                  pkgs.hixProject.shellFor {
                    tools = {
                      cabal = {};
                      haskell-language-server = "2.4.0.0";
                    };
                  };
               };
           }
      );
  nixConfig = {
    allow-import-from-derivation = true;
  };
}
