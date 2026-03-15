{ config, lib, pkgs, ... }:

let
  cfg = config.services.cloud-sync;

  providerPackages = {
    b2 = [];
    gdrive = [];
    onedrive = [];
  };

  syncScript = pkgs.writeShellScript "cloud-sync" ''
    set -euo pipefail

    REMOTE="${cfg.remoteName}"
    RCLONE="${pkgs.rclone}/bin/rclone"
    RCLONE_CONF="$HOME/.config/rclone/rclone.conf"

    if [ ! -f "$RCLONE_CONF" ]; then
      echo "ERROR: rclone not configured. Run 'rclone config' first to set up remote '$REMOTE'."
      exit 1
    fi

    if ! $RCLONE listremotes | grep -q "^''${REMOTE}:$"; then
      echo "ERROR: Remote '$REMOTE' not found in rclone config."
      echo "Available remotes:"
      $RCLONE listremotes
      exit 1
    fi

    ${lib.concatMapStringsSep "\n" (dir: ''
      echo "Syncing ${dir.remote} -> $HOME/${dir.local}"
      ${pkgs.coreutils}/bin/mkdir -p "$HOME/${dir.local}"
      $RCLONE sync "$REMOTE:${dir.remote}" "$HOME/${dir.local}" \
        --progress \
        --transfers 8 \
        --checkers 16 \
        --log-level INFO
    '') cfg.directories}

    echo "Cloud sync complete."
  '';

  setupScript = pkgs.writeShellScript "cloud-sync-setup" ''
    set -euo pipefail

    RCLONE="${pkgs.rclone}/bin/rclone"
    REMOTE="${cfg.remoteName}"
    PROVIDER="${cfg.provider}"

    echo "=== Cloud Storage Setup ==="
    echo "Provider: $PROVIDER"
    echo "Remote name: $REMOTE"
    echo ""

    case "$PROVIDER" in
      b2)
        echo "Backblaze B2 uses application keys."
        echo "Create one at: https://secure.backblaze.com/app_keys.htm"
        echo ""
        read -rp "Application Key ID: " KEY_ID
        read -rsp "Application Key: " APP_KEY
        echo ""
        $RCLONE config create "$REMOTE" b2 account "$KEY_ID" key "$APP_KEY"
        ;;
      gdrive)
        echo "Google Drive requires interactive OAuth."
        echo "A browser window will open for authentication."
        echo ""
        $RCLONE config create "$REMOTE" drive
        ;;
      onedrive)
        echo "OneDrive requires interactive OAuth."
        echo "A browser window will open for authentication."
        echo ""
        $RCLONE config create "$REMOTE" onedrive
        ;;
    esac

    echo ""
    echo "Testing connection..."
    if $RCLONE lsd "$REMOTE:" > /dev/null 2>&1; then
      echo "Connected to $REMOTE successfully."
    else
      echo "WARNING: Could not list remote. Check your configuration with 'rclone config'."
    fi
  '';
in
{
  options.services.cloud-sync = {
    enable = lib.mkEnableOption "cloud storage sync via rclone";

    provider = lib.mkOption {
      type = lib.types.enum [ "b2" "gdrive" "onedrive" ];
      description = "Cloud storage provider";
      example = "b2";
    };

    remoteName = lib.mkOption {
      type = lib.types.str;
      default = "cloud";
      description = "Name of the rclone remote";
    };

    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          remote = lib.mkOption {
            type = lib.types.str;
            description = "Path on the remote";
            example = "Documents";
          };
          local = lib.mkOption {
            type = lib.types.str;
            description = "Path relative to $HOME";
            example = "Documents";
          };
        };
      });
      default = [];
      description = "Directories to sync from cloud to local";
    };

    timerInterval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "How often to run background sync";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.rclone ];

    # One-shot setup helper: run `cloud-sync-setup` in a terminal
    home.file.".local/bin/cloud-sync-setup" = {
      executable = true;
      source = setupScript;
    };

    # One-shot sync: run `cloud-sync` manually or via service
    home.file.".local/bin/cloud-sync" = {
      executable = true;
      source = syncScript;
    };

    # Bootstrap sync on first login
    systemd.user.services.cloud-sync = {
      Unit = {
        Description = "Sync cloud storage via rclone (${cfg.provider})";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" ];
      };

      Install.WantedBy = [ "default.target" ];

      Service = {
        Type = "oneshot";
        ExecStart = "${syncScript}";
        # Don't fail the boot if cloud sync fails
        ExecStartPost = "${pkgs.bash}/bin/bash -c 'true'";
      };
    };

    # Periodic background sync
    systemd.user.timers.cloud-sync = {
      Unit.Description = "Periodic cloud storage sync";
      Install.WantedBy = [ "timers.target" ];
      Timer = {
        OnCalendar = cfg.timerInterval;
        Persistent = true;
      };
    };
  };
}
