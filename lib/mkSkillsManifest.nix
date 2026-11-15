{ layat }:
{
  # nixpkgs package set for the target system, forwarded to `layat.lib.mkManifest`.
  pkgs,
  # `layat.lib.projectRoot` or `layat.lib.homeRoot`.
  root,
  # A target path prefix, e.g. `presets.claude.project`.
  prefix,
  # `[ { name; src; subpath ? "."; method ? "symlink"; } ... ]`.
  skills,
}:
layat.lib.mkManifest {
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
