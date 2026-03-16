{ lib, ... }:
{
  # Nix-built QuickShell/bootstrap need Arch's GL stack (Nix Mesa has no DRI drivers)
  systemd.user.services.dms.Service = {
    Environment = [
      "LIBGL_DRIVERS_PATH=/usr/lib/dri"
      "__EGL_VENDOR_LIBRARY_DIRS=/usr/share/glvnd/egl_vendor.d"
      "LD_LIBRARY_PATH=/usr/lib"
    ];
    RestartSec = 3;
  };

  # DMS must wait for Hyprland's Wayland socket (hyprland-session.target),
  # not graphical-session.target which starts before the socket is ready.
  # On logout/login the old Wayland socket vanishes and DMS crashes before the
  # new Hyprland is ready — generous restart limits let it survive the gap.
  systemd.user.services.dms.Unit = {
    After = [ "hyprland-session.target" ];
    BindsTo = [ "hyprland-session.target" ];
    StartLimitIntervalSec = 60;
    StartLimitBurst = 10;
  };
  systemd.user.services.dms.Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];

  systemd.user.services.bootstrap.Service.Environment = [
    "LIBGL_DRIVERS_PATH=/usr/lib/dri"
    "__EGL_VENDOR_LIBRARY_DIRS=/usr/share/glvnd/egl_vendor.d"
    "LD_LIBRARY_PATH=/usr/lib"
  ];
}
