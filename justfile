set shell := ["bash", "-euo", "pipefail", "-c"]

default:
  @just check

nix-lock:
  nix flake lock

bootstrap:
  corepack enable
  pnpm install

check:
  cargo test --workspace
  pnpm check

fmt:
  cargo fmt --all
  pnpm exec biome format --write .

lint:
  cargo clippy --workspace --all-targets --all-features -- -D warnings

dev:
  pnpm dev

vm-build:
  nix build .#nixosConfigurations.vm-dev.config.system.build.vm

# Use system QEMU so GL/virgl works on non-NixOS hosts
_vm-exec *ARGS:
  sed "s|/nix/store/[^/]*/bin/qemu-system-x86_64|qemu-system-x86_64|" ./result/bin/run-*-vm | bash {{ARGS}}

# Run the VM with a fresh disk
vm-run: vm-build
  rm -f vm-dev.qcow2
  just _vm-exec

# Run the VM preserving disk state between runs
vm-run-persist: vm-build
  just _vm-exec

# Run the VM with serial console attached
vm-run-serial: vm-build
  just _vm-exec -s -- -serial mon:stdio
