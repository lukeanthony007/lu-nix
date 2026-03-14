# lu-nix

`lu-nix` is a Nix-first development workspace for modern Rust and TypeScript projects.

## What is included

- A `flake.nix` dev shell built around current Rust stable and a Node LTS line.
- A Rust workspace using edition `2024`.
- A TypeScript workspace using `pnpm`, strict compiler settings, and Biome.
- Common native build tools for OpenSSL, SQLite, and bindgen-style workflows.

## Layout

```text
.
├── apps/web
├── crates/core
├── .cargo
├── flake.nix
├── justfile
├── package.json
├── pnpm-workspace.yaml
└── Cargo.toml
```

## Bootstrap

1. Install Nix with flakes enabled.
2. Enter the dev shell with `nix develop`.
3. Enable Corepack once if needed: `corepack enable`.
4. Install JavaScript dependencies: `pnpm install`.
5. Run checks:
   - `just check`
   - or `cargo test --workspace && pnpm check`

## Notes

- `flake.lock` is intentionally not committed yet because `nix` is not available in the current machine session. Generate it with `nix flake lock` once Nix is installed.
- The shell is designed for Linux and macOS development. It includes Rust analysis tools, TypeScript language tooling, and native libraries commonly needed by Rust crates.
