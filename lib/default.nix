{ layat }:
{
  presets = import ./presets.nix;
  mkSkillsManifest = import ./mkSkillsManifest.nix { inherit layat; };
  mkSkillsDevShell = import ./mkSkillsDevShell.nix { inherit layat; };
  inherit (layat.lib)
    projectRoot
    homeRoot
    mkOutOfStoreSymlink
    mkRootRelativeSymlink
    ;
}
