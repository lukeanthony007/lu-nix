{ config, pkgs, lib, ... }:

#
# Appliance home-manager profile
#
# Wires: Hyprland → Foot → raia-shell
# No DMS, no browser, no productivity apps, no cloud-sync.
#
{
  imports = [
    ./appliance/hyprland.nix
    ./appliance/foot.nix
    ./appliance/provision.nix
  ];

  home.packages = with pkgs; [
    btop
    fastfetch
    foot
    nerd-fonts.jetbrains-mono
  ];

  home.sessionVariables = {
    EDITOR = lib.mkForce "vim";
    TERMINAL = lib.mkForce "foot";
  };

  # Dark theme defaults
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };
}
