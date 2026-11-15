{
  description = "agenput-skills-nix example: place skills from anthropics/skills for Claude Code and Codex";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    agenput-skills.url = "github:airRnot1106/agenput-skills-nix";

    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      agenput-skills,
      anthropic-skills,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      inherit (agenput-skills.lib) presets;

      skills = lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (
        system:
        agenput-skills.lib.mkSkills {
          pkgs = nixpkgs.legacyPackages.${system};
          sets.agent-skills = {
            scope = "project";
            paths = [
              presets.claude.project
              presets.codex.project
            ];
            sources = [
              {
                src = anthropic-skills;
                dir = "skills";
                skills = [
                  "pdf"
                  "docx"
                  "xlsx"
                ];
              }
            ];
          };
        }
      );
    in
    {
      layat = lib.mapAttrs (_: s: s.layat) skills;

      devShells = lib.mapAttrs (_: s: { default = s.devShell; }) skills;
    };
}
