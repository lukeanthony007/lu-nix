{ pkgs, lib, ... }:

#
# Appliance Hyprland config
#
# Minimal: no DMS, no app launchers beyond Foot.
# Single workspace, single terminal, appliance-focused keybinds.
#
let
  hypr-kill = pkgs.writeShellScriptBin "hypr-kill" ''
    hyprctl dispatch killactive
  '';
in
{
  home.packages = [ hypr-kill ];

  # Create stub config directories so Hyprland source lines don't fail
  home.activation.hyprConfigStubs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.config/hypr/dms"
    for f in colors outputs layout cursor binds execs general keybinds rules windowrules; do
      [ -f "$HOME/.config/hypr/dms/$f.conf" ] || touch "$HOME/.config/hypr/dms/$f.conf"
    done
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    systemd.enable = true;
    settings = {};

    extraConfig = ''
      exec-once = dbus-update-activation-environment --systemd --all
      exec-once = systemctl --user start hyprland-session.target

      # DMS stubs (empty but sourced for compat)
      source = ~/.config/hypr/dms/colors.conf
      source = ~/.config/hypr/dms/outputs.conf
      source = ~/.config/hypr/dms/layout.conf
      source = ~/.config/hypr/dms/cursor.conf

      # --- Appliance defaults ---

      $mod = CTRL

      # Environment
      env = NIXOS_OZONE_WL,1

      # General
      general {
        gaps_in = 0
        gaps_out = 0
        border_size = 2
        layout = dwindle
      }

      decoration {
        rounding = 0
        blur {
          enabled = false
        }
        shadow {
          enabled = false
        }
      }

      animations {
        enabled = false
      }

      misc {
        vrr = 1
        enable_anr_dialog = false
        disable_hyprland_logo = true
        disable_splash_rendering = true
      }

      cursor {
        hide_on_key_press = true
      }

      # --- Keybinds ---

      # Terminal (primary action)
      bind = $mod, Return, exec, foot
      bind = $mod SHIFT, Return, exec, foot

      # Window management
      bind = $mod, X, exec, hypr-kill
      bind = Alt, F4, exec, hypr-kill
      bind = $mod, F, fullscreen, 1
      bind = $mod SHIFT, F, fullscreen, 0
      bind = Alt, Tab, movefocus, d

      # Workspace
      bind = $mod, up, workspace, -1
      bind = $mod, down, workspace, +1

      # Monitor auto-detect (for VM and varied hardware)
      monitor = , preferred, auto, 1
    '';
  };
}
