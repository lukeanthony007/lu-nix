{ pkgs, ... }:

let
  qsConfigDir = ./settings-app;

  settingsApp = pkgs.writeShellScriptBin "lu-nix-settings" ''
    exec ${pkgs.quickshell}/bin/quickshell -p "${qsConfigDir}"
  '';
in
{
  home.packages = [ settingsApp ];

  xdg.desktopEntries.lu-nix-settings = {
    name = "lu-nix Settings";
    comment = "System configuration and debug tools";
    exec = "${settingsApp}/bin/lu-nix-settings";
    icon = "preferences-system";
    categories = [ "Settings" "System" ];
    terminal = false;
  };
}
