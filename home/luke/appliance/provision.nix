{ config, lib, pkgs, ... }:

#
# First-boot provisioning check
#
# On first graphical session login, if provisioning is incomplete,
# launches a Foot terminal with the provisioning flow instead of
# the normal raia-shell.
#
# This is a safety net — the main provisioning path is the
# `raia-provision` command available system-wide via the raia module.
#
let
  provisionCheck = pkgs.writeShellScript "raia-provision-check" ''
    RAIA_HOME="$HOME/.raia"

    # If already provisioned, nothing to do
    [ -f "$RAIA_HOME/.provisioned" ] && exit 0

    # Not provisioned — launch a terminal with the provisioning tool
    ${pkgs.foot}/bin/foot -e raia-provision
  '';
in
{
  systemd.user.services.raia-provision-check = {
    Unit = {
      Description = "Raia first-boot provisioning check";
      After = [ "hyprland-session.target" ];
      ConditionPathExists = "!%h/.raia/.provisioned";
    };

    Install.WantedBy = [ "hyprland-session.target" ];

    Service = {
      Type = "oneshot";
      ExecStart = provisionCheck;
      Environment = [
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_RUNTIME_DIR=%t"
      ];
      TimeoutStartSec = "10min";
    };
  };
}
