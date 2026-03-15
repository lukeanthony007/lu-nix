{ ... }:
{
  imports = [
    ../../modules
    ./hardware-configuration.nix
  ];

  networking.hostName = "desktop";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  };

  # AMD RX 5700 XT (RDNA 1)
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["amdgpu"];

  # Intel AX210 WiFi + Bluetooth
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Firmware
  hardware.enableRedistributableFirmware = true;

  # Logitech C922 webcam
  hardware.logitech.wireless.enable = false;

  # Gaming
  programs.steam.enable = true;
  programs.gamemode.enable = true;

  # Media
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Home automation
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "default_config"
      "met"
    ];
    config = {
      homeassistant = {
        name = "Home";
        unit_system = "metric";
      };
      default_config = {};
    };
  };
}
