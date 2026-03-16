{ ... }:
{
  imports = [
    ./editors.nix
    ./git.nix
    ./shell.nix
  ];

  # home.username and home.homeDirectory are set by the caller:
  # - NixOS HM module: derived from home-manager.users.<name>
  # - Standalone HM: set explicitly in flake.nix
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
