{ nput }:
{
  pkgs,
  # Manifest names to apply on shell entry, e.g. `[ "skills" ]`.
  names,
}:
pkgs.mkShellNoCC {
  packages = [ nput.packages.${pkgs.system}.nput ];
  shellHook = builtins.concatStringsSep "\n" (map (name: "nput apply ${name} --no-wait") names);
}
