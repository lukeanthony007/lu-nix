{ config, lib, pkgs, ... }:
{
  imports = [
    ../../modules
  ];

  networking.hostName = "vm-dev";

  boot.loader.grub = {
    enable = true;
    device = "nodev";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  services.greetd.settings.initial_session = {
    command = let
      niri = lib.getExe' config.programs.niri.package "niri-session";
    in builtins.toString (pkgs.writeShellScript "niri-initial-session" ''
        mkdir -p "$HOME/.config/niri/dms"
        # Create stub DMS includes so niri can parse config.kdl before DMS generates them
        for f in alttab binds colors layout outputs wpblur; do
          [ -f "$HOME/.config/niri/dms/$f.kdl" ] || touch "$HOME/.config/niri/dms/$f.kdl"
        done
        # Ensure hm.kdl exists (home-manager symlink may not be ready yet)
        if [ ! -e "$HOME/.config/niri/hm.kdl" ]; then
          printf 'hotkey-overlay {\n    skip-at-startup\n}\n' > "$HOME/.config/niri/hm.kdl"
        fi
        exec ${niri}
      '');
    user = "luke";
  };

  services.qemuGuest.enable = true;

  virtualisation.vmVariant = {
    virtualisation = {
      cores = 4;
      diskSize = 8192;
      graphics = true;
      memorySize = 8192;
      qemu.options = [
        "-vga none"
        "-device virtio-gpu-gl-pci"
        "-display gtk,gl=on"
        "-audiodev pipewire,id=audio0"
        "-device intel-hda"
        "-device hda-duplex,audiodev=audio0"
      ];
    };
  };
}
