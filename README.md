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

## Acknowledgements

- [nput](https://github.com/yasunori0418/nput)
- [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix)
