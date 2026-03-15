{ pkgs, ... }:
{
  systemd.user.services.clone-nvchad = {
    Unit = {
      Wants = ["network-online.target"];
      After = ["network-online.target"];
      Description = "Clone NvChad config if missing";
    };

    Install.WantedBy = ["default.target"];

    Service = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = "${pkgs.bash}/bin/bash -c 'if [ ! -d $HOME/.config/nvim/.git ]; then rm -rf $HOME/.config/nvim; ${pkgs.git}/bin/git clone --depth 1 https://github.com/NvChad/starter $HOME/.config/nvim; fi'";
    };
  };

  systemd.user.services.clone-wallpapers = {
    Unit = {
      Wants = ["network-online.target"];
      After = ["network-online.target"];
      Description = "Clone wallpapers repo if missing";
    };

    Install.WantedBy = ["default.target"];

    Service = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = "${pkgs.bash}/bin/bash -c 'if [ ! -d $HOME/Pictures/Wallpapers/.git ]; then rm -rf $HOME/Pictures/Wallpapers; ${pkgs.git}/bin/git clone --depth 1 https://github.com/lukeanthony007/Wallpapers.git $HOME/Pictures/Wallpapers; fi'";
    };
  };
}
