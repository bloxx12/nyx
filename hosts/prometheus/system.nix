{
  config,
  lib,
  ...
}: let
  inherit (lib) optionals mkIf mkForce;

  dev = config.modules.device;
in {
  config = {
    modules = {
      device = {
        type = "laptop";
        cpu.type = "intel";
        gpu.type = "intel"; # nvidia drivers :b:roke
        monitors = ["eDP-1" "HDMI-A-1"];
        hasBluetooth = true;
        hasSound = true;
        hasTPM = true;
      };
      system = {
        mainUser = "notashelf";
        fs = ["btrfs" "vfat" "ntfs"];
        autoLogin = true;

        boot = {
          loader = "systemd-boot";
          enableKernelTweaks = true;
          initrd.enableTweaks = true;
          loadRecommendedModules = true;
          tmpOnTmpfs = true;
        };

        video.enable = true;
        sound.enable = true;
        bluetooth.enable = false;
        printing.enable = false;

        networking = {
          optimizeTcp = true;
          tailscale = {
            enable = true;
            isClient = true;
          };
        };

        virtualization = {
          enable = false;
          docker.enable = false;
          qemu.enable = true;
          podman.enable = false;
        };
      };
      usrEnv = {
        isWayland = true;
        desktop = "Hyprland";
        useHomeManager = true;
      };

      programs = {
        git.signingKey = "419DBDD3228990BE";

        cli.enable = true;
        gui.enable = true;

        gaming = {
          enable = true;
          chess.enable = true;
        };
        default = {
          terminal = "foot";
        };
        override = {};
      };
    };

    fileSystems = {
      "/".options = ["compress=zstd" "noatime"];
      "/home".options = ["compress=zstd"];
      "/nix".options = ["compress=zstd" "noatime"];
    };

    hardware = {
      nvidia = mkIf (builtins.elem dev.gpu ["nvidia" "hybrid-nv"]) {
        open = mkForce false;

        prime = {
          offload.enable = true;
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };

    boot = {
      kernelParams =
        [
          "nohibernate"
        ]
        ++ optionals ((dev.cpu == "intel") && (dev.gpu != "hybrid-nv")) [
          "i915.enable_fbc=1"
          "i915.enable_psr=2"
        ];
    };

    console.earlySetup = true;
  };
}
