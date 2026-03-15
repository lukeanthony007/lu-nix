# lu-nix

`lu-nix` is a VM-first NixOS flake that preserves a Rust and TypeScript development baseline.

## Current focus

- Keep the existing Rust and TypeScript workspace usable on its own.
- Build and validate a NixOS VM before any host installation work.
- Use Niri plus Home Manager as the first desktop target.

## Layout

```text
.
├── apps/web
├── crates/core
├── flake.nix
├── home/luke
│   ├── dms.nix
│   ├── editors.nix
│   ├── foot.nix
│   ├── git.nix
│   ├── niri.nix
│   ├── packages.nix
│   ├── services.nix
│   ├── shell.nix
│   └── vscode.nix
├── hosts
│   ├── desktop
│   ├── laptop
│   └── vm-dev
├── justfile
├── modules
│   ├── default.nix
│   ├── base.nix
│   ├── desktop
│   ├── dev
│   ├── services
│   └── users
├── package.json
└── pnpm-workspace.yaml
```

## What exists today

- A `nix develop` shell for Rust stable, Rust 2024, Node LTS, and `pnpm`.
- `nixosConfigurations.vm-dev` as the primary NixOS VM target.
- `nixosConfigurations.desktop` as the real-hardware target with Steam, Jellyfin, and Home Assistant.
- Shared NixOS modules for base system setup, Niri, DankMaterialShell, audio, Docker, SSH, Rust, and TypeScript.
- Home Manager configuration for the `luke` user, including Niri, DMS, foot, VS Code, fish, and starship.
- A placeholder `hosts/laptop` tree for future hardware-specific work.

## Bootstrap

1. Install Nix with flakes enabled.
2. Generate the lockfile: `nix flake lock`
3. Enter the dev shell: `nix develop`
4. Install JavaScript dependencies: `pnpm install`
5. Run the language checks: `just check`

## VM workflow

1. Build the VM target: `just vm-build`
2. Run the generated VM launcher from `./result/bin/`
3. Log in as `luke`

The VM user currently has the bootstrap password `luke`. That is acceptable for a disposable VM target and should be changed before any non-VM deployment work.

## Validation goals for `vm-dev`

- Boot succeeds
- Greetd login succeeds
- Niri session starts
- Terminal and browser launch
- Network is available
- PipeWire audio stack is present
- Clipboard tools are available
- Portals are enabled
- Rust and TypeScript toolchains are installed
- Docker is enabled

## Notes

- `hosts/laptop/hardware-configuration.nix` is a placeholder and is not exported in the flake outputs yet.
- SSH password authentication is disabled; set up public key auth via console login before relying on SSH.
