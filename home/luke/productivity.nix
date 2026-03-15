{ pkgs, ... }:
{
  home.packages = with pkgs; [
    deluge-gtk
    discord
    obsidian
    signal-desktop
    spotify
    zoom-us
  ];
}
