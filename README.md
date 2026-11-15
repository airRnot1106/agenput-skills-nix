# agenput-skills-nix

Thin [layat](https://github.com/yasunori0418/layat) wrapper for placing agent skills.

## Usage

See [`example/`](example/).

For a more practical example, please see [my dotfiles](https://github.com/airRnot1106/dotfiles/blob/4575aee3bc122b3daf69939ae273b8e17783080f/nix/agent-skills/flake.nix).

## Migrating from nput

nput was renamed to layat. Rename the `nput.<system>.<name>` flake output to
`layat.<system>.<name>`, as the layat CLI only reads the `layat` output.

## `lib`

- `presets.<tool>.project` / `presets.<tool>.global` — path per tool
  (`agents`, `codex`, `opencode`, `claude`, `copilot`, `cursor`, `windsurf`,
  `antigravity`, `gemini`, `pi`).
- `mkSkillsManifest { pkgs, root, prefix, skills }` — one manifest, one tool.
  `skills = [ { name; src; subpath ? "."; method ? "symlink"; } ]`.
- `mkSkillsDevShell { pkgs, names }` — devShell fragment. `shellHook` runs
  `layat apply <name> --no-wait` per name. Compose via `inputsFrom`.
- `projectRoot` / `homeRoot` / `mkOutOfStoreSymlink` / `mkRootRelativeSymlink` —
  re-exported from `layat.lib`, so consumers don't need `layat` as a direct
  flake input.

## Acknowledgements

- [layat](https://github.com/yasunori0418/layat)
- [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix)
