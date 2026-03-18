{ pkgs, ... }:

let
  qsConfigDir = ./settings-app;

  settingsApp = pkgs.writeShellScriptBin "lunix-settings" ''
    exec ${pkgs.quickshell}/bin/quickshell -p "${qsConfigDir}"
  '';
in
{
  home.packages = [ settingsApp ];

  xdg.desktopEntries.lunix-settings = {
    name = "Lunix Settings";
    comment = "System configuration and debug tools";
    exec = "${settingsApp}/bin/lunix-settings";
    icon = "preferences-system";
    categories = [ "Settings" "System" ];
    terminal = false;
  };
}
