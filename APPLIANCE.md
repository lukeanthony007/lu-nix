# Raia Continuity Appliance

A minimal NixOS profile that boots directly into a guarded raia-shell experience.

## Boot path

```
hardware → GRUB → systemd → raia-core.service
                           → greetd → Hyprland → Foot → raia-shell
```

- `raia-core` starts as a system service on boot
- greetd auto-logs in and starts Hyprland
- Hyprland launches Foot via a user service
- Foot's shell is a launcher script that waits for core readiness, then starts `raia-shell`

## Build and run

### Quick start (stub core)

Uses a minimal HTTP stub instead of real raia-core — validates the full boot path.

```bash
just appliance-run
```

### Full build (real raia-shell)

Build raia-shell from source first:

```bash
just raia-shell-build      # builds raia-shell binary
just appliance-full        # builds binary + VM image
just appliance-run         # runs the VM
```

### Persist disk state

To keep provisioning state between VM restarts:

```bash
just appliance-run-persist
```

## First-boot provisioning

On first boot, the appliance is not yet provisioned. The shell launcher detects this and drops into a diagnostic Fish prompt with instructions.

Run provisioning:

```
raia-provision
```

This prompts for:
- **Anthropic API key** — stored at `~/.raia/secrets/anthropic.key` (mode 0600)

It also creates:
- `~/.raia/domain.toml` — appliance domain manifest
- `~/.raia/deployment.json` — deployment context (appliance/production/established)
- `~/.raia/.provisioned` — marker file

After provisioning, restart core:

```
sudo systemctl restart raia-core
```

Then open a new Foot terminal or restart the session.

## Deployment context

The appliance boots with a conservative default context:

| Field | Value |
|-------|-------|
| Embodiment | `appliance` |
| Environment | `production` |
| Trust tier | `established` |
| Label | `raia-appliance` |

This context is set in `~/.raia/deployment.json` and passed to raia-core via environment variables. Gated actions respect this context through the trust model.

Inspect the active context via raia-shell:

```
/diag
/status
```

## Inspecting failures

### raia-core won't start

```bash
systemctl status raia-core
journalctl -u raia-core -f
```

Common causes:
- Not provisioned (run `raia-provision`)
- Port 4111 in use
- Missing API key

### Shell won't connect

The Foot launcher waits up to 60s for core readiness. If it times out, it drops to a diagnostic Fish shell with instructions.

```bash
# Check core health manually
curl http://localhost:4111/health/ready
```

### Hyprland won't start

Falls back to a Fish shell on the TTY with a diagnostic message. Switch to TTY2 (Ctrl+Alt+F2) for a login prompt.

```bash
journalctl --user -u hyprland-session
```

### Unclean shutdown / reboot

The raia-core service is configured with `Restart=on-failure` (5 retries in 60s). The systemd journal preserves crash context across reboots.

### Network unavailable

raia-core and raia-shell function locally. If external API calls fail (e.g., Anthropic), the runtime reports errors through the shell's response annotations. The appliance remains interactive.

## What's included vs. stripped

### Included

- Hyprland (compositor)
- greetd (session launcher)
- PipeWire (audio)
- Fish (fallback shell)
- Foot (terminal)
- System fonts
- Networking (NetworkManager)
- SSH
- `raia-core` service
- `raia-shell` binary
- `raia-provision` tool

### Stripped (vs. desktop profile)

- Gaming (Steam, RetroArch, gamescope)
- Productivity (Discord, Obsidian, Signal, Zoom)
- Browser (Zen)
- Cloud sync (rclone)
- VSCode
- Home Assistant
- Jellyfin
- Docker
- DMS (desktop shell)
- Bootstrap welcome wizard
- General workstation packages

## Files

```
hosts/appliance/default.nix      # Host profile (boot, services, VM config)
modules/services/raia.nix         # raia-core systemd service + provisioning
home/luke/appliance.nix           # Home Manager entry (imports below)
home/luke/appliance/hyprland.nix  # Simplified Hyprland for appliance
home/luke/appliance/foot.nix      # Foot → raia-shell launcher
home/luke/appliance/provision.nix # First-boot provisioning check service
packages/raia-core-stub.nix       # Stub server for boot-path testing
```
