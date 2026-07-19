{
  description = "agenput-skills-nix example: place skills from anthropics/skills for Claude Code";

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
      self,
      nixpkgs,
      agenput-skills,
      anthropic-skills,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      skills = [
        {
          name = "pdf";
          src = anthropic-skills;
          subpath = "skills/pdf";
        }
        {
          name = "docx";
          src = anthropic-skills;
          subpath = "skills/docx";
        }
        {
          name = "xlsx";
          src = anthropic-skills;
          subpath = "skills/xlsx";
        }
      ];
    in
    {
      nput = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          skills-claude = agenput-skills.lib.mkSkillsManifest {
            inherit pkgs skills;
            root = agenput-skills.lib.projectRoot;
            prefix = agenput-skills.lib.presets.claude.project;
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            inputsFrom = [
              (agenput-skills.lib.mkSkillsDevShell {
                inherit pkgs;
                # For names, specify the manifest name defined in nput.${system} (e.g., skills-claude).
                names = builtins.attrNames self.nput.${system};
              })
            ];
          };
        }
      );
    };
}
