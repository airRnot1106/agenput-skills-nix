{ layat }:
{
  pkgs,
  # Manifest names to apply on shell entry, e.g. `[ "skills" ]`.
  names,
  # Optional entrypoint flake passed to `layat apply -f`. layat's entrypoint
  # discovery only looks at CWD, so point this at the flake that defines the
  # manifests when it does not live at the repo root.
  entrypoint ? null,
}:
let
  flag = if entrypoint == null then "" else " -f ${entrypoint}";
in
pkgs.mkShellNoCC {
  packages = [ layat.packages.${pkgs.stdenv.hostPlatform.system}.layat ];
  shellHook = builtins.concatStringsSep "\n" (
    map (name: "layat apply ${name} --no-wait${flag}") names
  );
}
