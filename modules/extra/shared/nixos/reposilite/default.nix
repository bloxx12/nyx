{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf getExe;

  cfg = config.services.reposilite;
in {
  options.services.reposilite = {
    enable = mkEnableOption "reposilite - maven repository manager";

    package = mkOption {
      type = with types; nullOr package;
      default = null; # reposilite is not in nixpkgs
      description = "Package to install";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall for reposilite";
    };

    settings = {
      port = mkOption {
        type = types.int;
        default = 8084;
        description = "Port to listen on";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/reposilite";
        description = "Working directory";
      };

      user = mkOption {
        type = types.str;
        default = "reposilite";
        description = "User to run reposilite as";
      };

      group = mkOption {
        type = types.str;
        default = "reposilite";
        description = "Group to run reposilite as";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.package != null;
        message = ''
          The default package is `null` as reposilite is not yet in nixpkgs.
          Please provide your own package with the {option}`services.reposilite.package` option.
        '';
      }
    ];

    environment.systemPackages = [cfg.package];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
      cfg.settings.port
    ];

    users = {
      groups.reposilite = {
        name = cfg.settings.group;
      };

      users.reposilite = {
        group = cfg.settings.user;
        home = cfg.settings.dataDir;
        isSystemUser = true;
        createHome = true;
      };
    };

    systemd.services."reposilite" = {
      description = "Reposilite - Maven repository";
      wantedBy = ["multi-user.target"];
      script = let
        inherit (cfg.settings) dataDir port;
      in ''
        ${getExe cfg.package} --working-directory "${dataDir}" --port "${toString port}"
      '';

      serviceConfig = {
        inherit (cfg.settings) user group;

        WorkingDirectory = cfg.settings.dataDir;
        SuccessExitStatus = 0;
        TimeoutStopSec = 10;
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
