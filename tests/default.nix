{ pkgs, agenput }:
let
  inherit (pkgs) lib;
  repo = ./fixtures/repo;

  entriesOf =
    set:
    (agenput.mkSkills {
      inherit pkgs;
      sets.t = {
        scope = "project";
        paths = [ ".claude/skills" ];
      }
      // set;
    }).entries.t;

  subpaths = set: lib.mapAttrs (_: entry: entry.subpath) (entriesOf set);
  fails = set: !(builtins.tryEval (builtins.deepSeq (subpaths set) null)).success;
  source = attrs: { sources = [ ({ src = repo; } // attrs) ]; };

  shell =
    sets:
    (agenput.mkSkills {
      inherit pkgs sets;
    }).devShell.shellHook;

  cases = {
    "a name resolves to the directory that holds SKILL.md" =
      subpaths (source {
        dir = "skills";
        skills = [ "docx" ];
      }) == {
        ".claude/skills/docx" = "skills/docx";
      };

    "a name is found at any depth" =
      subpaths (source {
        skills = [ "nested" ];
      }) == {
        ".claude/skills/nested" = "skills/group/nested";
      };

    "all selects every skill under dir" =
      lib.attrNames (
        subpaths (source {
          dir = "skills";
          skills = "all";
        })
      ) == [
        ".claude/skills/docx"
        ".claude/skills/nested"
        ".claude/skills/pdf"
      ];

    "every skill is placed under every path, once per path" =
      lib.attrNames (
        entriesOf (
          source {
            dir = "skills";
            skills = [ "pdf" ];
          }
          // {
            paths = [
              agenput.presets.claude.project
              agenput.presets.codex.project
              ".claude/skills"
            ];
          }
        )
      ) == [
        ".claude/skills/pdf"
        ".codex/skills/pdf"
      ];

    "a pinned path selects one of two same-named skills" =
      subpaths (source {
        skills = [
          {
            name = "pdf";
            path = "examples/pdf";
          }
        ];
      }) == {
        ".claude/skills/pdf" = "examples/pdf";
      };

    "a skill at the source root is placed under its pinned name" =
      subpaths {
        sources = [
          {
            src = ./fixtures/root-skill;
            skills = [
              {
                name = "solo";
                path = ".";
              }
            ];
          }
        ];
      } == {
        ".claude/skills/solo" = ".";
      };

    "a live skill links to its directory under the root" =
      let
        entry =
          (entriesOf {
            sources = [
              {
                live = "dev/skills";
                skills = [ "release" ];
              }
            ];
          }).".claude/skills/release";
      in
      entry.src.path == "dev/skills" && entry.subpath == "release";

    "a live skill is not placed where it already sits" =
      lib.attrNames (entriesOf {
        paths = [
          ".agents/skills"
          ".claude/skills"
        ];
        sources = [
          {
            live = ".agents/skills";
            skills = [ "release" ];
          }
        ];
      }) == [ ".claude/skills/release" ];

    "a missing name fails" = fails (source {
      skills = [ "nope" ];
    });
    "a name found twice in one source fails" = fails (source {
      skills = [ "pdf" ];
    });
    "all fails when a name is found twice" = fails (source {
      skills = "all";
    });
    "the same name from two sources fails" = fails {
      sources = [
        {
          src = repo;
          dir = "skills";
          skills = [ "pdf" ];
        }
        {
          src = ./fixtures/other;
          skills = [ "pdf" ];
        }
      ];
    };
    "a pinned path without SKILL.md fails" = fails (source {
      skills = [
        {
          name = "skills";
          path = "skills";
        }
      ];
    });
    "a pinned name that differs from the directory name fails" = fails (source {
      skills = [
        {
          name = "renamed";
          path = "skills/docx";
        }
      ];
    });
    "a dir that does not exist fails" = fails (source {
      dir = "missing";
      skills = "all";
    });
    "a dir that escapes the source fails" = fails (source {
      dir = "../repo";
      skills = "all";
    });
    "all on a live source fails" = fails {
      sources = [
        {
          live = "dev/skills";
          skills = "all";
        }
      ];
    };
    "src together with live fails" = fails {
      sources = [
        {
          src = repo;
          live = "dev/skills";
          skills = [ "pdf" ];
        }
      ];
    };
    "a source with neither src nor live fails" = fails {
      sources = [ { skills = [ "pdf" ]; } ];
    };
    "an unknown scope fails" =
      !(builtins.tryEval
        (agenput.mkSkills {
          inherit pkgs;
          sets.t = {
            scope = "home";
            paths = [ ".claude/skills" ];
          };
        }).layat.t.drvPath
      ).success;
    "an unknown option fails" = fails {
      tools = [ "claude" ];
    };

    "the shell hook applies each set by name from its prebuilt manifest" =
      let
        hook = shell {
          one = {
            scope = "project";
            paths = [ ".claude/skills" ];
          };
        };
      in
      lib.hasInfix " apply --all --manifest 'one=/nix/store/" hook && lib.hasSuffix " --no-wait" hook;

    "the shell hook is empty without sets" = shell { } == "";
  };
in
lib.attrNames (lib.filterAttrs (_: passed: !passed) cases)
