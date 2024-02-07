{
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault mkForce mkOverride mkMerge mkIf optionals;

  sys = config.modules.system;
in {
  config = {
    boot = {
      # kernel console loglevel
      consoleLogLevel = 3;
      # always use the latest kernel instead of the old-ass lts one
      kernelPackages = mkOverride 500 sys.boot.kernel;
      # additional packages supplying kernel modules
      extraModulePackages = mkDefault sys.boot.extraModulePackages;
      # configuration to be appended to the generated modprobe.conf
      extraModprobeConfig = mkDefault sys.boot.extraModprobeConfig;
      # whether to enable support for Linux MD RAID arrays
      # I don't know why this defaults to true, how many people use RAID anyway?
      # also on > 23.11, this will throw a warning if neither MAILADDR nor PROGRAM are set
      swraid.enable = mkDefault false;

      # settings shared between bootloaders
      # they are set unless system.boot.loader != none
      loader = {
        # if set to 0, space needs to be held to get the boot menu to appear
        timeout = mkForce 2;
        # whether to copy the necessary boot files into /boot, so /nix/store is not needed by the boot loader.
        generationsDir.copyKernels = true;

        # allow installation to modify EFI variables
        efi.canTouchEfiVariables = true;
      };

      # instructions on how /tmp should be handled
      # if your system is low on ram, you should avoid tmpfs to prevent hangups while compiling
      tmp = {
        # /tmp on tmpfs, lets it live on your ram
        # it defaults to FALSE, which means you will use disk space instead of ram
        # enable tmpfs tmp on anything except servers and builders
        useTmpfs = sys.boot.tmpOnTmpfs;

        # If not using tmpfs, which is naturally purged on reboot, we must clean
        # /tmp ourselves. /tmp should be volatile storage!
        cleanOnBoot = mkDefault (!config.boot.tmp.useTmpfs);

        # The size of the tmpfs, in percentage form
        # this defaults to 50% of your ram, which is a good default
        # but should be tweaked based on your systems capabilities
        tmpfsSize = mkDefault "75%";
      };

      # initrd and kernel tweaks
      # if you intend to copy paste this section, read what each parameter or module does before doing so
      # or perish, I am not responsible for your broken system. if you copy paste this section without reading
      # and later realise your mistake, you are a moron.
      initrd = mkMerge [
        (mkIf sys.boot.initrd.enableTweaks {
          # Verbosity of the initrd
          # disabling verbosity removes only the mandatory messages generated by the NixOS
          verbose = false;

          # strip copied binaries and libraries from inframs
          # saves 30~ mb space according to the nix derivation
          systemd.strip = true;

          # enable systemd in initrd
          # extremely experimental, just the way I like it on a production machine
          systemd.enable = true;

          # List of modules that are always loaded by the initrd
          kernelModules = [
            "nvme"
            "xhci_pci"
            "ahci"
            "btrfs"
            "sd_mod"
            "dm_mod"
            "tpm"
          ];

          # the set of kernel modules in the initial ramdisk used during the boot process
          availableKernelModules = [
            "usbhid"
            "sd_mod"
            "dm_mod"
            "uas"
            "usb_storage"
            "rtsx_pci_sdmmc" # Realtek PCI-Express SD/MMC Card Interface driver
          ];
        })

        (mkIf sys.boot.initrd.optimizeCompressor
          {
            compressor = "zstd";
            compressorArgs = ["-19" "-T0"];
          })
      ];

      # https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html
      kernelParams =
        (optionals sys.boot.enableKernelTweaks [
          # https://en.wikipedia.org/wiki/Kernel_page-table_isolation
          # auto means kernel will automatically decide the pti state
          "pti=auto" # on | off

          # CPU idle behaviour
          #  poll: slightly improve performance at cost of a hotter system (not recommended)
          #  halt: halt is forced to be used for CPU idle
          #  nomwait: Disable mwait for CPU C-states
          "idle=nomwait" # poll | halt | nomwait

          # enable IOMMU for devices used in passthrough
          # and provide better host performance in virtualization
          "iommu=pt"

          # disable usb autosuspend
          "usbcore.autosuspend=-1"

          # disables resume and restores original swap space
          "noresume"

          # allows systemd to set and save the backlight state
          "acpi_backlight=native" # none | vendor | video | native

          # prevent the kernel from blanking plymouth out of the fb
          "fbcon=nodefer"

          # disable the cursor in vt to get a black screen during intermissions
          "vt.global_cursor_default=0"

          # disable displaying of the built-in Linux logo
          "logo.nologo"
        ])
        ++ (optionals sys.boot.silentBoot [
          # tell the kernel to not be verbose
          "quiet"

          # kernel log message level
          "loglevel=3" # 1: sustem is unusable | 3: error condition | 7: very verbose

          # udev log message level
          "udev.log_level=3"

          # lower the udev log level to show only errors or worse
          "rd.udev.log_level=3"

          # disable systemd status messages
          # rd prefix means systemd-udev will be used instead of initrd
          "systemd.show_status=auto"
          "rd.systemd.show_status=auto"
        ]);
    };
  };
}
