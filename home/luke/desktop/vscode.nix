{ pkgs, ... }:
{
  home.activation.vscodeSettings = ''
    mkdir -p "$HOME/.config/Code/User"
    cp -f ${../config/vscode-settings.json} "$HOME/.config/Code/User/settings.json"
    chmod 644 "$HOME/.config/Code/User/settings.json"
  '';

  systemd.user.services.vscode-extensions = {
    Unit = {
      Description = "Install VS Code extensions";
      After = ["default.target"];
    };
    Install.WantedBy = ["default.target"];
    Service = {
      Type = "oneshot";
      ExecStart = let
        extensions = [
          "andrsdc.base16-themes"
          "anthropic.claude-code"
          "beardedbear.beardedtheme"
          "jnoortheen.nix-ide"
          "openai.chatgpt"
          "skellock.just"
          "usernamehw.errorlens"
        ];
        cmds = builtins.concatStringsSep " && " (map (ext: "${pkgs.vscode}/bin/code --install-extension ${ext}") extensions);
      in "${pkgs.bash}/bin/bash -c '${cmds} || true'";
    };
  };
}
