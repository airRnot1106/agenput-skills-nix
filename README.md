# agenput-skills-nix

Thin [nput](https://github.com/yasunori0418/nput) wrapper for placing agent skills.

## Usage

See [`example/`](example/).

For a more practical example, please see [my dotfiles](https://github.com/airRnot1106/dotfiles/blob/4575aee3bc122b3daf69939ae273b8e17783080f/nix/agent-skills/flake.nix).

## `lib`

- `presets.<tool>.project` / `presets.<tool>.global` — path per tool
  (`agents`, `codex`, `opencode`, `claude`, `copilot`, `cursor`, `windsurf`,
  `antigravity`, `gemini`, `pi`).
- `mkSkillsManifest { pkgs, root, prefix, skills }` — one manifest, one tool.
  `skills = [ { name; src; subpath ? "."; method ? "symlink"; } ]`.
- `mkSkillsDevShell { pkgs, names }` — devShell fragment. `shellHook` runs
  `nput apply <name> --no-wait` per name. Compose via `inputsFrom`.
- `projectRoot` / `homeRoot` / `mkOutOfStoreSymlink` — re-exported from
  `nput.lib`, so consumers don't need `nput` as a direct flake input.

## Acknowledgements

- [nput](https://github.com/yasunori0418/nput)
- [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix)
