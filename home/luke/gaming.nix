{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dolphin-emu
    gamescope
    mangohud
    pcsx2
    protonup-qt
    (retroarch.withCores (cores: with cores; [
      beetle-psx-hw    # PS1
      fceumm           # NES
      flycast          # Dreamcast
      mgba             # GBA
      mupen64plus      # N64
      ppsspp           # PSP
      snes9x           # SNES
    ]))
  ];

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
