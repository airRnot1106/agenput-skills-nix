# agenput-skills-nix

Place agent skills with [layat](https://github.com/yasunori0418/layat) (formerly known as **nput**). Specify the skills you want, and the library will locate each one in its source and symlink it to your target directories.

## Usage

```nix
skills = agenput-skills.lib.mkSkills {
  inherit pkgs;
  sets.agent-skills = {
    scope = "project";
    paths = [
      agenput-skills.lib.presets.claude.project
      agenput-skills.lib.presets.codex.project
    ];
    sources = [
      { src = inputs.anthropic-skills; dir = "skills"; skills = [ "pdf" "docx" ]; }
      { src = inputs.mattpocock; skills = [ "grilling" ]; }
      { live = ".agents/skills"; skills = [ "release" ]; }
    ];
  };
};
```

Add the outputs to your flake:

```nix
layat.${system} = skills.layat;
devShells.${system}.default = skills.devShell;   # or inputsFrom = [ skills.devShell ]
```

Starting the devshell links the skills. The set name is also the layat config name, so commands like `layat status agent-skills`, `layat gitignore agent-skills`, and `layat reset agent-skills` work on the set.

See [`example/`](example/) for a complete flake.

## `mkSkills { pkgs, sets }`

`mkSkills` returns three attributes:

| Attribute | Value |
| --- | --- |
| `layat` | One layat manifest per set. Assign it to the flake output `layat.<system>`. |
| `devShell` | A shell with the pinned layat CLI. Its `shellHook` applies every set. |
| `entries` | The layat `entries` of each set, for a layat host module or for inspection. |

### `sets.<name>`

| Option | Type | Meaning |
| --- | --- | --- |
| `scope` | `"project"` or `"global"` | `"project"` links skills under the git root, while `"global"` targets `$HOME`. |
| `paths` | list of strings | Target directories relative to the scope root. Every skill in the set is symlinked into all specified paths. |
| `sources` | list of sources | Where to pull skills from. Defaults to `[ ]`. |

You can use `presets.<tool>.project` and `presets.<tool>.global` for common tools like `agents`, `codex`, `opencode`, `claude`, `copilot`, `cursor`, `windsurf`, `antigravity`, `gemini`, and `pi`. For anything else, pass a custom path.

`mkSkills` does not check that a path fits the chosen scope. For example, using `presets.windsurf.global` inside a `"project"` set will still place skills inside the repository.

### Sources

Specify either `src` or `live`, but not both.

| Option | Type | Meaning |
| --- | --- | --- |
| `src` | path, flake input, or derivation | A tree in the Nix store. Use a `flake = false` input for external repositories. |
| `live` | string | A directory on disk linked directly so changes take effect without reapplying. Relative paths are resolved against the scope root. |
| `dir` | string | Subdirectory to inspect within the source. Defaults to `"."`. |
| `skills` | `"all"` or a list | Which skills to install. |

A skill is a directory containing a `SKILL.md` file. The directory name is the skill name. Entries in `skills` can take two forms:

- A string like `"pdf"`, which tells `mkSkills` to search for a matching directory under `dir`.
- An attribute set `{ name; path; }` where `path` is relative to `dir`. This skips the directory search. If a skill lives at the root of a source, set `name` manually. Otherwise, `name` must match the directory name.

Setting `skills = "all"` installs every skill found under `dir`.

Because derivations are not built during evaluation and `live` directories live outside the Nix store, `mkSkills` cannot inspect or search them. For derivations, you must use the explicit `{ name; path; }` syntax. For `live` sources, a string targets the folder of that name under `dir`, while `"all"` is not supported.

A `live` skill will not be linked back into its own source directory.

### Errors

Evaluation fails if:

- a requested skill name is missing or matches multiple directories within a source,
- multiple sources in the same set define skills with the same name,
- a path given via `{ name; path; }` does not contain a `SKILL.md`,
- `dir` does not exist, or `dir` or `path` contains `..` or is an absolute path.

## Acknowledgements

- [layat](https://github.com/yasunori0418/layat)
- [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix)
