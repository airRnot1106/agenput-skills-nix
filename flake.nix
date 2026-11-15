{
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://yasunori0418.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "yasunori0418.cachix.org-1:mC1j+M5A6063OHaOB5bH2nS0BiCW/BJsSRiOWjLeV9o="
    ];
  };

  inputs = {
    layat.url = "github:yasunori0418/layat";
  };

  outputs =
    { self, layat, ... }:
    let
      inherit (layat.inputs) nixpkgs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      lib = import ./lib { inherit layat; };

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          failed = import ./tests {
            inherit pkgs;
            agenput = self.lib;
          };
        in
        {
          tests =
            if failed == [ ] then
              pkgs.runCommandLocal "agenput-skills-tests" { } "touch $out"
            else
              throw "agenput-skills tests failed:\n${nixpkgs.lib.concatStringsSep "\n" failed}";

          formatting =
            pkgs.runCommandLocal "agenput-skills-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; }
              ''
                nixfmt --check ${./flake.nix} ${./lib}/*.nix ${./tests/default.nix} ${./example/flake.nix}
                touch $out
              '';
        }
      );
    };
}
