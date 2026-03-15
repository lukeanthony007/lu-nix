{ ... }:
{
  imports = [
    ./dms.nix
    ./editors.nix
    ./foot.nix
    ./git.nix
    ./niri.nix
    ./packages.nix
    ./services.nix
    ./shell.nix
    ./vscode.nix
  ];

  home.username = "luke";
  home.homeDirectory = "/home/luke";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
