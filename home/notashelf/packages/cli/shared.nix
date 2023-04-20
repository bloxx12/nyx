{
  osConfig,
  lib,
  pkgs,
  ...
}:
with lib; let
  programs = osConfig.modules.programs;
in {
  config = (mkIf programs.cli.enable) {
    home.packages = with pkgs; [
      # CLI
      cloneit
      catimg
      duf
      todo
      hyperfine
      fzf
      file
      unzip
      ripgrep
      rsync

      bandwhich
      grex
      fd
      xh
      jq
      figlet
      lm_sensors
      bitwarden-cli
      dconf
      gcc
      cmake
      trash-cli
      cached-nix-shell
      ttyper
      xorg.xhost
      nitch
      fastfetch
      python39Packages.requests # move
    ];
  };
}
