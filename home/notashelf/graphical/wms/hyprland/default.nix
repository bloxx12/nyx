{
  pkgs,
  lib,
  config,
  inputs,
  self,
  osConfig,
  ...
}:
with lib; let
  mkService = lib.recursiveUpdate {
    Unit.PartOf = ["graphical-session.target"];
    Unit.After = ["graphical-session.target"];
    Install.WantedBy = ["graphical-session.target"];
  };

  hyprshot = pkgs.writeShellScriptBin "hyprshot" ''
    #!/bin/bash
    hyprctl keyword animation "fadeOut,0,8,slow" && ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -w 0 -b 5e81acd2)" - | swappy -f -; hyprctl keyword animation "fadeOut,1,8,slow"
  '';

  grimblast = inputs.hyprland-contrib.packages.${pkgs.system}.grimblast;

  wl-clip-persist = self.packages.${pkgs.system}.wl-clip-persist;

  env = osConfig.modules.usrEnv;
  device = osConfig.modules.device;
  sys = osConfig.modules.system;
in {
  imports = [./config.nix];

  config = mkIf ((sys.video.enable) && (env.isWayland && (env.desktop == "Hyprland"))) {
    home.packages = [
      hyprshot
      grimblast
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      systemdIntegration = true;
      package = inputs.hyprland.packages.${pkgs.system}.default.override {
        nvidiaPatches = (device.gpu == "nvidia") || (device.gpu == "hybrid-nv");
      };
    };

    services.gammastep = {
      enable = true;
      provider = "geoclue2";
    };

    systemd.user.services = {
      swaybg = mkService {
        Unit.Description = "Wallpaper chooser service";
        Service = {
          ExecStart = "${lib.getExe pkgs.swaybg} -i ${./wall.png}";
          Restart = "always";
        };
      };

      cliphist = mkService {
        Unit.Description = "Clipboard history service";
        Service = {
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${lib.getExe pkgs.cliphist} store";
          Restart = "always";
        };
      };

      wl-clip-persist = mkService {
        Unit.Description = "Persistent clipboard for Wayland";
        Service = {
          ExecStart = "${lib.getExe wl-clip-persist} --clipboard both";
          Restart = "always";
        };
      };
    };
  };
}
