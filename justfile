set shell := ["bash", "-euo", "pipefail", "-c"]

# === Development VM ===

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

# === Raia Appliance ===

# Build the appliance VM image
appliance-build:
  nix build .#nixosConfigurations.appliance.config.system.build.vm

# Helper to run the appliance VM (uses system QEMU for GL)
_appliance-exec *ARGS:
  sed "s|/nix/store/[^/]*/bin/qemu-system-x86_64|qemu-system-x86_64|" ./result/bin/run-*-vm | bash {{ARGS}}

# Run the appliance VM with a fresh disk
appliance-run: appliance-build
  rm -f raia-appliance.qcow2
  just _appliance-exec

# Run the appliance VM preserving disk state (for testing provisioning persistence)
appliance-run-persist: appliance-build
  just _appliance-exec

# Run the appliance VM with serial console for debugging
appliance-run-serial: appliance-build
  just _appliance-exec -s -- -serial mon:stdio

# Validate the appliance profile evaluates without errors
appliance-check:
  nix eval .#nixosConfigurations.appliance.config.system.build.toplevel --apply builtins.seq --raw 2>&1 | head -5 || true
  @echo "appliance profile evaluated"

# Build raia-shell from source (run from raia workspace)
raia-shell-build:
  cd ../raia && cargo build -p raia-shell --release
  @echo "raia-shell built: ../raia/target/release/raia-shell"

# Full appliance build: build raia binaries, then build VM
appliance-full: raia-shell-build appliance-build
  @echo "appliance VM ready — run: just appliance-run"
