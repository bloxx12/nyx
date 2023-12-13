{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}: let
  dev = osConfig.modules.device;
  acceptedTypes = ["desktop" "laptop" "lite" "hybrid"];
in {
  config = lib.mkIf (builtins.elem dev.type acceptedTypes) {
    home.packages = with pkgs; [
      playerctl # CLI interface for playerctld
      mpc_cli # CLI interface for mpd
      cava # CLI music visualizer (cavalier is a gui alternative)
    ];

    services = {
      playerctld.enable = true;
      mpris-proxy.enable = true;
      mpd-mpris.enable = true;

      # MPRIS 2 support to mpd
      mpdris2 = {
        enable = true;
        notifications = true;
        multimediaKeys = true;
        mpd = {
          # for some reason config.xdg.userDirs.music is not a "path" - possibly because it has $HOME in its name?
          inherit (config.services.mpd) musicDirectory;
        };
      };

      # mpd service
      mpd = {
        enable = true;
        musicDirectory = "${config.home.homeDirectory}/Media/Music";
        network = {
          startWhenNeeded = true;
          listenAddress = "127.0.0.1";
          port = 6600;
        };

        extraConfig = ''
          audio_output {
            type "pipewire"
            name "PipeWire"
            auto_resample "no"
            use_mmap "yes"
          }

          audio_output {
            type                    "fifo"
            name                    "fifo"
            path                    "/tmp/mpd.fifo"
            format                  "44100:16:2"
          }

          auto_update "yes"
        '';
      };

      # discord rich presence for mpd
      mpd-discord-rpc = {
        enable = true;
        settings = {
          format = {
            details = "$title";
            state = "On $album by $artist";
            large_text = "$album";
            small_image = "";
          };
        };
      };
    };

    programs = {
      # music tagger and organizer
      # FIXME: another build failure (13.12.2022)
      # beets = import ./beets.nix {inherit config;};

      # ncmpcpp configuration, has cool stuff like visualiser
      ncmpcpp = import ./ncmpcpp.nix {inherit config pkgs;};

      /*
      # yams service
      # TODO: figure out a way to provide the lastfm authentication declaratively

      systemd.user.services.yams = {
        Unit = {
          Description = "Last.FM scrobbler for MPD";
          After = ["mpd.service"];
        };
        Service = {
          ExecStart = "${pkgs.yams}/bin/yams -N";
          Environment = "NON_INTERACTIVE=1";
          Restart = "always";
        };
        Install.WantedBy = ["default.target"];
      };
      */
    };
  };
}
