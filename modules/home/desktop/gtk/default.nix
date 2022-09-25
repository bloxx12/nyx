{ pkgs, lib, config, fetchzip, inputs, ... }:
with lib;
let cfg = config.modules.desktop.gtk;
in {
  options.modules.desktop.gtk = { enable = mkEnableOption "gtk"; };

  config = mkIf cfg.enable {

    gtk = {
      enable = true;
      theme = {
        name = "Catppuccin";
        package = pkgs.catppuccin-gtk.override { size = "compact"; };
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      font = {
        name = "Lato";
        size = 13;
      };
      gtk3.extraConfig = {
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
        gtk-xft-rgba = "rgb";
      };
      gtk2.extraConfig = ''
        gtk-xft-antialias=1
        gtk-xft-hinting=1
        gtk-xft-hintstyle="hintslight"
        gtk-xft-rgba="rgb"
      '';

    };
  };
}
