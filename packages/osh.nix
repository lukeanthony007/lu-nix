#
# Nix package for osh — the operator shell.
#
# Builds from source using a standalone Cargo.toml decoupled from the
# workspace (osh has no workspace-internal path deps).
#
# Requires --impure for local source path access.
#
{ pkgs
, osh-src
}:

let
  # Assemble a self-contained source tree:
  # - Cargo.toml and Cargo.lock from lunix (standalone, no workspace refs)
  # - Rust source from the repo
  src = pkgs.runCommand "osh-src" {} ''
    mkdir -p $out/src
    cp -r ${osh-src}/src/* $out/src/
    cp ${./osh/Cargo.toml} $out/Cargo.toml
    cp ${./osh/Cargo.lock} $out/Cargo.lock
  '';
in
pkgs.rustPlatform.buildRustPackage {
  pname = "osh";
  version = "0.1.0";

  inherit src;
  cargoLock.lockFile = ./osh/Cargo.lock;

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [
    openssl
  ];

  meta = {
    description = "OSH — the operator shell over the continuity runtime";
    license = pkgs.lib.licenses.mit;
    mainProgram = "osh";
  };
}
