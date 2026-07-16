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
    nput.url = "github:yasunori0418/nput";
  };

  outputs =
    { nput, ... }:
    {
      lib = import ./lib { inherit nput; };
    };
}
