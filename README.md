# lu-nix

`lu-nix` is a VM-first NixOS flake that preserves a Rust and TypeScript development baseline.

## Current focus

- Keep the existing Rust and TypeScript workspace usable on its own.
- Build and validate a NixOS VM before any host installation work.
- Use Niri plus Home Manager as the first desktop target.

## Layout

```text
.
├── flake.nix
├── home/luke
│   ├── default.nix       # Core profile (shell, git, editors)
│   ├── desktop.nix       # Graphical environment (niri, DMS, foot, vscode)
│   ├── gaming.nix        # RetroArch, emulators, gamescope
│   ├── productivity.nix  # Discord, Spotify, Signal, Obsidian
│   ├── dms.nix
│   ├── editors.nix
│   ├── foot.nix
│   ├── git.nix
│   ├── niri.nix
│   ├── services.nix
│   ├── shell.nix
│   └── vscode.nix
├── hosts
│   ├── desktop
│   ├── laptop
│   └── vm-dev
├── justfile
├── modules
│   ├── default.nix       # All groups (convenience)
│   ├── core.nix          # base + users + ssh
│   ├── graphical.nix     # audio, DMS, fonts, niri
│   ├── development.nix   # Rust toolchain, Node/pnpm runtime
│   ├── base.nix
│   ├── desktop/
│   ├── dev/
│   ├── services/
│   └── users/
├── apps/web
├── crates/core
├── package.json
└── pnpm-workspace.yaml
```

## Architecture

### System modules — composable groups

Hosts import the groups they need:

| Group | File | Includes |
|---|---|---|
| Core | `modules/core.nix` | base system, user accounts, SSH |
| Graphical | `modules/graphical.nix` | niri, DMS, audio, fonts |
| Development | `modules/development.nix` | Rust toolchain, Node/pnpm runtime |

`modules/default.nix` imports all three for convenience. Hosts can import selectively:

```nix
# Full workstation (current hosts)
imports = [ ../../modules ];

# Future headless server
imports = [ ../../modules/core.nix ];

# Graphical but no dev tools
imports = [ ../../modules/core.nix ../../modules/graphical.nix ];
```

### Home profiles — per-host composition

`home/luke/default.nix` is the core profile (shell, git, editors) loaded for every host. Additional profiles are composed per-host via `mkHost`:

```nix
nixosConfigurations.vm-dev = mkHost {
  path = ./hosts/vm-dev;
  homeModules = [ ./home/luke/desktop.nix ];
};
nixosConfigurations.desktop = mkHost {
  path = ./hosts/desktop;
  homeModules = [
    ./home/luke/desktop.nix
    ./home/luke/gaming.nix
    ./home/luke/productivity.nix
  ];
};
```

### Dev tooling — no duplication

The `nix develop` shell provides the full dev workflow (cargo helpers, LSP servers, linters, formatters). System-level `modules/dev/*` only installs what the NixOS host needs to build and run (toolchain, linker, build deps). No overlap.

## What exists today

- A `nix develop` shell for Rust stable, Rust 2024, Node LTS, and `pnpm`.
- `nixosConfigurations.vm-dev` as the primary NixOS VM target (desktop profile).
- `nixosConfigurations.desktop` as the real-hardware target (desktop + gaming + productivity, with Steam, Jellyfin, and Home Assistant).
- Composable NixOS modules: core, graphical, and development groups.
- Composable Home Manager profiles: core, desktop, gaming, and productivity.
- A placeholder `hosts/laptop` tree for future hardware-specific work.

## Bootstrap

1. Install Nix with flakes enabled.
2. Generate the lockfile: `nix flake lock`
3. Enter the dev shell: `nix develop`
4. Install JavaScript dependencies: `pnpm install`
5. Run the language checks: `just check`

## VM workflow

1. Build the VM target: `just vm-build`
2. Run the generated VM launcher: `just vm-run`
3. Log in as `luke`

The VM user currently has the bootstrap password `luke`. That is acceptable for a disposable VM target and should be changed before any non-VM deployment work.

## Notes

- `hosts/laptop/hardware-configuration.nix` is a placeholder and is not exported in the flake outputs yet.
- SSH password authentication is disabled; set up public key auth via console login before relying on SSH.
