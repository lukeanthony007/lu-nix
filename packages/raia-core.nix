#
# Nix package for raia-core — continuity runtime server.
#
# Multi-stage from-source build:
#   Stage 1: Build raia-kernel-node NAPI .node module from Rust workspace
#   Stage 2: Fetch npm dependencies (fixed-output derivation via bun install)
#   Stage 3: Bun compile — self-contained binary embedding runtime + JS + NAPI
#
# The Cargo workspace lives at the infra root with all repos as direct
# siblings. Repos with their own [workspace] (aether, anima, materia) get
# minimal workspace manifests to avoid Cargo nested-workspace conflicts.
# Nayru keeps its own workspace for inherited deps (regex, cpal, rodio).
#
# Requires --impure for local source path access.
#

{ pkgs

# Source trees — passed from flake.nix (no hardcoded paths here).
# All require --impure for local source access.
, raia-src
, raia-app-src
, raia-cognition-src
, raia-kernel-src
, raia-kernel-node-src
, osh-src
, nayru-src
, aether-src
, anima-src
, materia-src
, mana-src
, mythra-src
, cargoLockFile
, workspace-cargo-toml
}:

let
  # ── Stage 1: Rust NAPI module ─────────────────────────────────────────────

  # Assemble the Cargo workspace mirroring the flat infra/ layout:
  #   $out/              — workspace root (Cargo.toml here)
  #   $out/raia/         — raia source (TS, raia-app, package.json)
  #   $out/raia-kernel/  — kernel crate
  #   $out/raia-kernel-node/ — NAPI bindings crate
  #   $out/osh/          — shell crate (workspace member)
  #   $out/nayru/        — sibling (keeps own workspace for inherited deps)
  #   $out/aether/       — sibling (stub workspace + aether-core)
  #   $out/anima/        — sibling (stub workspace + anima-core)
  #   $out/materia/      — sibling (stub workspace + materia-core)
  #   $out/mana/         — workspace member
  #   $out/mythra/       — workspace member
  rustWorkspace = pkgs.runCommand "raia-rust-workspace" {} ''
    mkdir -p $out

    # Workspace root
    cp ${workspace-cargo-toml} $out/Cargo.toml

    # Raia source (TS root — package.json, bun.lock, scripts)
    cp -rT ${raia-src} $out/raia
    chmod -R u+w $out/raia

    # Raia app (Next.js/Tauri — workspace member raia-app/src-tauri)
    cp -rT ${raia-app-src} $out/raia-app

    # Extracted Rust crates
    cp -rT ${raia-kernel-src} $out/raia-kernel
    cp -rT ${raia-kernel-node-src} $out/raia-kernel-node
    cp -rT ${osh-src} $out/osh

    # Nayru — keeps own workspace for inherited deps (regex, cpal, rodio)
    cp -rT ${nayru-src} $out/nayru

    # aether — only aether-core needed; stub workspace to avoid nested conflicts
    mkdir -p $out/aether/crates
    cp -rT ${aether-src}/crates/aether-core $out/aether/crates/aether-core
    # Stub test files referenced by aether-core [[test]] sections
    mkdir -p $out/aether/tests/integration $out/aether/tests/benchmarks
    touch $out/aether/tests/integration/storage_test.rs
    touch $out/aether/tests/integration/pipeline_test.rs
    touch $out/aether/tests/benchmarks/throughput.rs
    cat > $out/aether/Cargo.toml << 'EOF'
[workspace]
members = ["crates/aether-core"]
EOF

    # anima — only anima-core needed; stub workspace
    mkdir -p $out/anima/crates
    cp -rT ${anima-src}/crates/anima-core $out/anima/crates/anima-core
    cat > $out/anima/Cargo.toml << 'EOF'
[workspace]
members = ["crates/anima-core"]
EOF

    # materia — only materia-core needed; stub workspace
    mkdir -p $out/materia/crates
    cp -rT ${materia-src}/crates/materia-core $out/materia/crates/materia-core
    cat > $out/materia/Cargo.toml << 'EOF'
[workspace]
members = ["crates/materia-core"]
EOF

    # mana, mythra — workspace members (no [workspace] of their own)
    cp -rT ${mana-src} $out/mana
    cp -rT ${mythra-src} $out/mythra
  '';

  # Build the NAPI cdylib (.node file) from the assembled Rust workspace.
  # Only compiles raia-kernel-node and its transitive deps:
  #   raia-kernel → materia-core, anima-core, aether-core, mana, mythra
  napiModule = pkgs.rustPlatform.buildRustPackage {
    pname = "raia-kernel-node";
    version = "0.1.0";

    src = rustWorkspace;
    sourceRoot = "raia-rust-workspace";

    cargoLock.lockFile = cargoLockFile;

    cargoBuildFlags = [ "-p" "raia-kernel-node" ];

    nativeBuildInputs = with pkgs; [ pkg-config ];
    buildInputs = with pkgs; [ openssl ];

    # cdylib output — rename to NAPI convention
    # cargoBuildHook uses --target x86_64-unknown-linux-gnu, so output is under target/<triple>/
    installPhase = ''
      mkdir -p $out
      cp target/x86_64-unknown-linux-gnu/release/libraia_kernel_node.so $out/kernel-node.linux-x64-gnu.node
    '';

    doCheck = false;
  };

  # ── Stage 2: npm dependencies ─────────────────────────────────────────────

  # Fixed-output derivation: bun install with network access, pinned by hash.
  # Assembles the bun workspace structure (raia + materia-node + anima-node +
  # anima-context + kernel-node) and installs registry deps.
  npmDeps = pkgs.stdenv.mkDerivation {
    name = "raia-npm-deps";

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-Udj2Gv4jWDiE0GP8k/gC5PDIHUS2/YgciflRzvTc548=";

    nativeBuildInputs = with pkgs; [ bun cacert ];

    dontUnpack = true;
    dontFixup = true;

    buildPhase = ''
      export HOME=$TMPDIR

      # Assemble bun workspace layout matching raia/package.json workspaces:
      #   "../materia/crates/materia-node"
      #   "../anima/crates/anima-node"
      #   "../anima/packages/anima-context"
      #   "../raia-kernel-node"
      mkdir -p raia
      cp ${raia-src}/package.json raia/
      cp ${raia-src}/bun.lock raia/

      mkdir -p raia-kernel-node
      cp ${raia-kernel-node-src}/package.json raia-kernel-node/

      mkdir -p materia/crates/materia-node
      cp ${materia-src}/crates/materia-node/package.json materia/crates/materia-node/

      mkdir -p anima/crates/anima-node anima/packages/anima-context
      cp ${anima-src}/crates/anima-node/package.json anima/crates/anima-node/
      cp ${anima-src}/packages/anima-context/package.json anima/packages/anima-context/

      cd raia
      bun install --frozen-lockfile --ignore-scripts
    '';

    installPhase = ''
      cp -r node_modules $out
    '';
  };

in
# ── Stage 3: Bun compile ──────────────────────────────────────────────────

# Combine TypeScript source + NAPI module from Stage 1 + node_modules from
# Stage 2. Run bun build --compile to produce a self-contained binary that
# embeds: Bun runtime, all JS/TS source, NAPI .node module.

pkgs.stdenv.mkDerivation {
  pname = "raia-core";
  version = "0.1.0";

  src = raia-src;

  nativeBuildInputs = with pkgs; [ bun autoPatchelfHook ];
  buildInputs = with pkgs; [ stdenv.cc.cc.lib ];

  buildPhase = ''
    export HOME=$TMPDIR

    # Place extracted sibling repos where raia's TS imports expect them
    cp -rT ${raia-app-src} ../raia-app
    cp -rT ${raia-cognition-src} ../raia-cognition

    # Install pre-fetched node_modules
    cp -r ${npmDeps} node_modules
    chmod -R u+w node_modules

    # Replace workspace symlink for @raia/kernel-node with real content + NAPI binary
    rm -rf node_modules/@raia/kernel-node
    mkdir -p node_modules/@raia/kernel-node
    cp ${napiModule}/kernel-node.linux-x64-gnu.node node_modules/@raia/kernel-node/
    cp ${raia-kernel-node-src}/index.js node_modules/@raia/kernel-node/
    cp ${raia-kernel-node-src}/index.d.ts node_modules/@raia/kernel-node/ 2>/dev/null || true
    cp ${raia-kernel-node-src}/package.json node_modules/@raia/kernel-node/

    # Replace other workspace symlinks with their source
    rm -rf node_modules/@raia/materia-node
    rm -rf node_modules/@anima/node
    rm -rf node_modules/@anima/context

    # @anima/context is imported by raia-cognition — copy source
    if [ -d "${anima-src}/packages/anima-context" ]; then
      mkdir -p node_modules/@anima/context
      cp -r ${anima-src}/packages/anima-context/. node_modules/@anima/context/
    fi

    # Build self-contained binary
    # keytar (native keychain addon) and ffmpeg-static (Discord voice) are not needed at runtime
    bun build --compile ../raia-app/src-tauri/scripts/core-entry.ts \
      --external keytar --external ffmpeg-static \
      --outfile raia-core
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp raia-core $out/bin/raia-core
    chmod 0755 $out/bin/raia-core
  '';

  # Bun-compiled binary embeds JS + NAPI module in ELF sections.
  # Stripping corrupts the embedded content.
  dontStrip = true;
  dontPatchELF = true;

  # Expose intermediate stages for debugging and incremental builds
  passthru = {
    inherit napiModule npmDeps rustWorkspace;
  };

  meta = {
    description = "Raia Continuity Runtime — kernel + HTTP API server (built from source)";
    license = pkgs.lib.licenses.mit;
    mainProgram = "raia-core";
  };
}
