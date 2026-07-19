# agenput-skills-nix

Thin [nput](https://github.com/yasunori0418/nput) wrapper for placing agent skills.

## Usage

see [`example/`](example/).

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
