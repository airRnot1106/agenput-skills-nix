{ nput }:
{
  presets = import ./presets.nix;
  mkSkillsManifest = import ./mkSkillsManifest.nix { inherit nput; };
  mkSkillsDevShell = import ./mkSkillsDevShell.nix { inherit nput; };
  inherit (nput.lib) projectRoot homeRoot mkOutOfStoreSymlink;
}
