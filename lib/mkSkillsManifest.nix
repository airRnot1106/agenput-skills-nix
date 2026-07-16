{ nput }:
{
  # nixpkgs package set for the target system, forwarded to `nput.lib.mkManifest`.
  pkgs,
  # `nput.lib.projectRoot` or `nput.lib.homeRoot`.
  root,
  # A target path prefix, e.g. `presets.claude.project`.
  prefix,
  # `[ { name; src; subpath ? "."; method ? "symlink"; } ... ]`.
  skills,
}:
nput.lib.mkManifest {
  inherit pkgs root;
  entries = builtins.listToAttrs (
    map (skill: {
      name = "${prefix}/${skill.name}";
      value = {
        src = skill.src;
      }
      // (if skill ? subpath then { inherit (skill) subpath; } else { })
      // (if skill ? method then { inherit (skill) method; } else { });
    }) skills
  );
}
