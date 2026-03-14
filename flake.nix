{
  description = "2026-ready Rust and TypeScript development environment for lu-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [(import rust-overlay)];
        };

        rustToolchain =
          pkgs.rust-bin.stable.latest.default.override {
            extensions = [
              "clippy"
              "llvm-tools-preview"
              "rust-analyzer"
              "rust-src"
              "rustfmt"
            ];
            targets = [
              "wasm32-unknown-unknown"
            ];
          };

        nodejs = pkgs.nodejs_24 or pkgs.nodejs;
      in
      {
        formatter = pkgs.nixfmt-rfc-style;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bacon
            biome
            cargo-deny
            cargo-edit
            cargo-nextest
            fd
            git
            jq
            just
            llvmPackages_latest.clang
            llvmPackages_latest.lld
            nodejs
            openssl
            pkg-config
            pnpm
            ripgrep
            rustToolchain
            sqlite
            typescript-language-server
            vscode-langservers-extracted
            watchexec
          ];

          LIBCLANG_PATH = "${pkgs.llvmPackages_latest.libclang.lib}/lib";
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";

          shellHook = ''
            export PATH="$PWD/node_modules/.bin:$PATH"

            echo "lu-nix dev shell"
            echo "Rust: $(rustc --version)"
            echo "Node: $(node --version)"
            echo "pnpm: $(pnpm --version)"
          '';
        };
      });
}
