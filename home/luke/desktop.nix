{ inputs, pkgs, ... }:
{
  imports = [
    ./dms.nix
    ./foot.nix
    ./niri.nix
    ./services.nix
    ./vscode.nix
  ];

  home.packages = with pkgs; [
    btop
    bun
    claude-code
    codex
    fastfetch
    imv
    inputs.zen-browser.packages.${pkgs.system}.default
    gnome-text-editor
    mpv
    nautilus
    nerd-fonts.jetbrains-mono
    p7zip
    pavucontrol
    qemu
    rclone
    unzip
    vscode
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
  };
}
