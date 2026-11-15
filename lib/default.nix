{ layat }:
{
  presets = import ./presets.nix;

  mkSkills =
    { pkgs, sets }:
    let
      inherit (pkgs) lib;
      resolve = import ./resolve.nix {
        inherit lib;
        layatLib = layat.lib;
      };
      parsed =
        (lib.evalModules {
          modules = [
            {
              options.sets = lib.mkOption { type = lib.types.attrsOf resolve.setType; };
              config.sets = sets;
            }
          ];
        }).config.sets;
      resolved = lib.mapAttrs resolve.resolveSet parsed;
      manifests = lib.mapAttrs (
        name: set:
        layat.lib.mkManifest {
          inherit pkgs;
          inherit (set) root entries;
          # The shellHook apply and a manual `layat apply <name>` then count as the same origin.
          identity = "agenput-skills:${name}";
        }
      ) resolved;
      layatPackage = layat.packages.${pkgs.stdenv.hostPlatform.system}.layat;
    in
    {
      layat = manifests;
      entries = lib.mapAttrs (_: set: set.entries) resolved;
      devShell = pkgs.mkShellNoCC {
        packages = [ layatPackage ];
        # Without --manifest, `layat apply --all` would read the flake in the working directory instead.
        shellHook = lib.optionalString (manifests != { }) (
          layat.lib.mkApplyCommand {
            inherit pkgs layatPackage manifests;
            root = "all";
          }
          + " --no-wait"
        );
      };
    };
}
