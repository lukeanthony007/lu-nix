#
# Nix package for raia-core — continuity runtime server.
#
# Multi-stage from-source build:
#   Stage 1: Build raia-kernel-node NAPI .node module from Rust workspace
#   Stage 2: Fetch npm dependencies (fixed-output derivation via bun install)
#   Stage 3: Bun compile — self-contained binary embedding runtime + JS + NAPI
#
# The full Cargo workspace spans 7 repos (raia + aether, anima, materia,
# mana, mythra, nayru). Stage 1 assembles them in a parent directory that
# preserves the sibling-repo topology Cargo expects. Repos with their own
# [workspace] (aether, anima, materia) get minimal workspace manifests to
# avoid Cargo nested-workspace conflicts. Nayru stays as a true sibling
# (referenced via ../nayru in the raia Cargo.toml).
#
# Requires --impure for local source path access.
#

{ pkgs

# --- Local source paths (all require --impure) ---
, raia-src ? builtins.path {
    path = /home/luke/Source/infra/raia;
    name = "raia-src";
    filter = path: type:
      let base = baseNameOf path; in
      !(base == "node_modules" || base == "target" || base == "build"
        || base == ".git" || base == ".next" || base == ".turbo");
  }
, nayru-src ? builtins.path {
    path = /home/luke/Source/infra/nayru;
    name = "nayru-src";
    filter = path: type:
      let base = baseNameOf path; in
      !(base == "target" || base == ".git");
  }
, aether-src ? builtins.path {
    path = /home/luke/Source/infra/aether;
    name = "aether-src";
    filter = path: type:
      let base = baseNameOf path; in
      !(base == "target" || base == ".git");
  }
, anima-src ? builtins.path {
    path = /home/luke/Source/infra/anima;
    name = "anima-src";
    filter = path: type:
      let base = baseNameOf path; in
      !(base == "target" || base == ".git" || base == "node_modules");
  }
, materia-src ? builtins.path {
    path = /home/luke/Source/infra/materia;
    name = "materia-src";
    filter = path: type:
      let base = baseNameOf path; in
      !(base == "target" || base == ".git" || base == "node_modules");
  }
, mana-src ? builtins.path {
    path = /home/luke/Source/infra/mana;
    name = "mana-src";
    filter = path: type:
      let base = baseNameOf path; in
      !(base == "target" || base == ".git");
  }
, mythra-src ? builtins.path {
    path = /home/luke/Source/infra/mythra;
    name = "mythra-src";
    filter = path: type:
      let base = baseNameOf path; in
      !(base == "target" || base == ".git");
  }
}:

let
  # ── Stage 1: Rust NAPI module ─────────────────────────────────────────────

  # Assemble the full Cargo workspace preserving sibling-repo topology.
  #
  # Layout mirrors the real development structure:
  #   $out/raia/         — main workspace (Cargo.toml here)
  #   $out/nayru/        — sibling (../nayru path deps work naturally)
  #   $out/raia/repos/   — external crates (aether, anima, materia, mana, mythra)
  #
  # Repos that have their own [workspace] (aether, anima, materia) get
  # minimal workspace Cargo.toml files listing only the crates raia needs.
  # This prevents Cargo from seeing nested workspace conflicts while still
  # resolving `version.workspace = true` etc. in those crates.
  #
  # Nayru stays as a sibling because its crates use workspace-inherited deps
  # (regex, cpal, rodio, etc.) that must resolve from nayru's own workspace.
  rustWorkspace = pkgs.runCommand "raia-rust-workspace" {} ''
    mkdir -p $out/raia $out/nayru

    # Copy raia workspace root (filtered — no node_modules/target/build)
    cp -rT ${raia-src} $out/raia
    chmod -R u+w $out/raia

    # Copy nayru as sibling — its crates use workspace-inherited deps
    cp -rT ${nayru-src} $out/nayru

    # --- Build repos/ with real source ---
    rm -rf $out/raia/repos
    mkdir -p $out/raia/repos

    # aether — only aether-core needed (hardcoded deps, no workspace inheritance)
    mkdir -p $out/raia/repos/aether/crates
    cp -rT ${aether-src}/crates/aether-core $out/raia/repos/aether/crates/aether-core
    # Stub test files referenced by aether-core [[test]] sections
    mkdir -p $out/raia/repos/aether/tests/integration $out/raia/repos/aether/tests/benchmarks
    touch $out/raia/repos/aether/tests/integration/storage_test.rs
    touch $out/raia/repos/aether/tests/integration/pipeline_test.rs
    touch $out/raia/repos/aether/tests/benchmarks/throughput.rs
    cat > $out/raia/repos/aether/Cargo.toml << 'EOF'
[workspace]
members = ["crates/aether-core"]
EOF

    # anima — only anima-core needed (hardcoded deps)
    mkdir -p $out/raia/repos/anima/crates
    cp -rT ${anima-src}/crates/anima-core $out/raia/repos/anima/crates/anima-core
    cat > $out/raia/repos/anima/Cargo.toml << 'EOF'
[workspace]
members = ["crates/anima-core"]
EOF

    # materia — only materia-core needed (hardcoded deps)
    mkdir -p $out/raia/repos/materia/crates
    cp -rT ${materia-src}/crates/materia-core $out/raia/repos/materia/crates/materia-core
    cat > $out/raia/repos/materia/Cargo.toml << 'EOF'
[workspace]
members = ["crates/materia-core"]
EOF

    # mana, mythra — raia workspace members (no [workspace] of their own)
    cp -rT ${mana-src} $out/raia/repos/mana
    cp -rT ${mythra-src} $out/raia/repos/mythra
  '';

  # Build the NAPI cdylib (.node file) from the assembled Rust workspace.
  # Only compiles raia-kernel-node and its transitive deps:
  #   raia-kernel → materia-core, anima-core, aether-core, mana, mythra
  napiModule = pkgs.rustPlatform.buildRustPackage {
    pname = "raia-kernel-node";
    version = "0.1.0";

    src = rustWorkspace;
    sourceRoot = "raia-rust-workspace/raia";

    # Use the workspace Cargo.lock directly (impure path, read at eval time)
    cargoLock.lockFile = /home/luke/Source/infra/raia/Cargo.lock;

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
      #   "src/raia-kernel-node"
      mkdir -p raia/src/raia-kernel-node
      cp ${raia-src}/package.json raia/
      cp ${raia-src}/bun.lock raia/
      cp ${raia-src}/src/raia-kernel-node/package.json raia/src/raia-kernel-node/

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

    # Install pre-fetched node_modules
    cp -r ${npmDeps} node_modules
    chmod -R u+w node_modules

    # Replace workspace symlink for @raia/kernel-node with real content + NAPI binary
    rm -rf node_modules/@raia/kernel-node
    mkdir -p node_modules/@raia/kernel-node
    cp ${napiModule}/kernel-node.linux-x64-gnu.node node_modules/@raia/kernel-node/
    cp src/raia-kernel-node/index.js node_modules/@raia/kernel-node/
    cp src/raia-kernel-node/index.d.ts node_modules/@raia/kernel-node/ 2>/dev/null || true
    cp src/raia-kernel-node/package.json node_modules/@raia/kernel-node/

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
    bun build --compile src/raia-app/src-tauri/scripts/core-entry.ts \
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
