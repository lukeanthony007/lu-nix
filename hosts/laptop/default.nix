{ ... }:
{
  imports = [
    ../../modules
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";
}
