{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    bun
    claude-code
    codex
    btop
    deluge-gtk
    discord
    dolphin-emu
    fastfetch
    gamescope
    imv
    mangohud
    mpv
    inputs.zen-browser.packages.${pkgs.system}.default
    gnome-text-editor
    nautilus
    nerd-fonts.jetbrains-mono
    obsidian
    p7zip
    pavucontrol
    pcsx2
    protonup-qt
    qemu
    rclone
    signal-desktop
    (retroarch.withCores (cores: with cores; [
      beetle-psx-hw    # PS1
      fceumm           # NES
      flycast          # Dreamcast
      mgba             # GBA
      mupen64plus      # N64
      ppsspp           # PSP
      snes9x           # SNES
    ]))
    spotify
    unzip
    vscode
    zoom-us
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

  home.activation.retroarchConfig = ''
    cfg="$HOME/.config/retroarch/retroarch.cfg"
    if [ ! -f "$cfg" ]; then
      mkdir -p "$(dirname "$cfg")"
      cat > "$cfg" << 'RACFG'
menu_driver = "xmb"
menu_wallpaper_opacity = "1.000000"
menu_framebuf_enable = "true"
xmb_menu_color_theme = "20"
xmb_theme = "0"
xmb_alpha_factor = "95"
RACFG
    fi
  '';
}
