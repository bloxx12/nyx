{
  # https://github.com/notashelf/nyx
  description = "My NixOS configuration with *very* questionable stability";

  outputs = {
    self,
    nixpkgs,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} ({withSystem, ...}: {
      # systems for which the `perSystem` attributes will be built
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        # and more if they can be supported ...
      ];

      imports = [
        # add self back to inputs to use as `inputs.self`
        # I depend on inputs.self *at least* once
        {config._module.args._inputs = inputs // {inherit (inputs) self;};}

        # parts and modules from inputs
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.treefmt-nix.flakeModule

        # parts of the flake
        ./flake/modules # nixos and home-manager modules provided by this flake
        ./flake/pkgs # packages exposed by the flake
        ./flake/schemas # home-baked schemas for upcoming nix schemas
        ./flake/templates # flake templates # TODO: bash and python

        ./flake/args.nix # args that are passsed to the flake, moved away from the main file
        ./flake/deployments.nix # deploy-rs configurations for active hosts
        ./flake/lib.nix # extended library referenced across the flake
        ./flake/pre-commit.nix # pre-commit hooks, performed before each commit inside the devshell
        ./flake/treefmt.nix # treefmt configuration
        ./flake/shell.nix # devShells explosed by the flake
      ];

      flake = let
        inherit (self) lib;
      in {
        # entry-point for nixos configurations
        nixosConfigurations = import ./hosts {inherit inputs lib withSystem;};

        # Recovery images for my hosts
        # build with `nix build .#images.<hostname>`
        # alternatively hosts can be built with `nix build .#nixosConfigurations.hostName.config.system.build.isoImage`
        images = import ./hosts/images.nix {inherit inputs;};
      };

      perSystem = {
        inputs',
        config,
        pkgs,
        ...
      }: {
        # set pkgs to the legacyPackages inherited from config instead of the one
        # initiated by flake-parts
        imports = [{_module.args.pkgs = config.legacyPackages;}];

        # provide the formatter for nix fmt
        formatter = inputs'.nyxpkgs.packages.alejandra-no-ads;
      };
    });

  inputs = {
    # We build against nixos unstable, because stable takes way too long to get things into
    # more versions with or without pinned branches can be added if deemed necessary
    # stable? never heard of her
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    # sometimes nixpkgs breaks something I need, pin a working commit when that occurs
    # nixpkgs-pinned.url = "github:NixOS/nixpkgs/b610c60e23e0583cdc1997c54badfd32592d3d3e";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Powered by
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Ever wanted nix error messages to be even more cryptic?
    # Try flake-utils today! (Devs I beg you please stop)
    flake-utils.url = "github:numtide/flake-utils";

    # this will work one day
    # (eelco please)
    flake-schemas.url = "github:DeterminateSystems/flake-schemas";

    # doesn't build
    nixSchemas.url = "github:DeterminateSystems/nix/flake-schemas";

    # Feature-rich and convenient fork of the Nix package manager
    nix-super.url = "github:privatevoid-net/nix-super";

    # Repo for hardare-specific NixOS modules
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Nix wrapper for building and testing my system
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # multi-profile Nix-flake deploy
    deploy-rs.url = "github:serokell/deploy-rs";

    # A tree-wide formatter
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixfmt = {
      url = "github:piegamesde/nixfmt/rfc101-style";
      flake = false;
    };

    # Project shells
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # guess what this does
    # come on, try
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    # sandbox wrappers for programs
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    # This exists, I guess
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    # Impermanence
    # doesn't offer much above properly used symlinks but it *is* convenient
    impermanence.url = "github:nix-community/impermanence";

    # secure-boot on nixos
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };

    # nix-index database
    nix-index-db = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix gaming packages
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs-small";
    };

    atticd = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs-small";
    };

    # Secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Rust overlay
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    # Nix Language server
    nil = {
      url = "github:oxalica/nil";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    # neovim nightly packages for nix
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Personal package overlay
    nyxpkgs.url = "github:NotAShelf/nyxpkgs";

    # Personal neovim-flake
    neovim-flake = {
      url = "github:NotAShelf/neovim-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs-small";
        nil.follows = "nil";
        flake-utils.follows = "flake-utils";
        flake-parts.follows = "flake-parts";
      };
    };

    air-quality-monitor = {
      url = "github:NotAShelf/air-quality-monitor";
      inputs.nixpkgs.follows = "nixpkgs-small";
    };

    # use my own wallpapers repository to provide various wallpapers as nix packages
    wallpkgs = {
      url = "github:NotAShelf/wallpkgs";
      inputs.nixpkgs.follows = "nixpkgs-small";
    };

    # anyrun program launcher
    anyrun.url = "github:Kirottu/anyrun";
    anyrun-nixos-options = {
      url = "github:n3oney/anyrun-nixos-options";
      inputs = {
        flake-parts.follows = "flake-parts";
      };
    };

    # aylur's gtk shell (ags)
    ags.url = "github:Aylur/ags";

    # spicetify for theming spotify
    spicetify = {
      url = "github:the-argus/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-small";
    };

    # schizophrenic firefox configuration
    schizofox = {
      url = "github:schizofox/schizofox";
      inputs = {
        nixpkgs.follows = "nixpkgs-small";
        flake-parts.follows = "flake-parts";
        nixpak.follows = "nixpak";
      };
    };

    # mailserver on nixos
    # simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
    # FIXME: this uses a fork that awaits merge, switch back to master once it's merged
    # <https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/merge_requests/316>
    simple-nixos-mailserver = {
      url = "gitlab:dotlambda/nixos-mailserver/sieve-fix";
      inputs = {
        "nixpkgs".follows = "nixpkgs";
        "nixpkgs-22_11".follows = "";
        "nixpkgs-23_05".follows = "";
      };
    };

    # Hyprland & Hyprland Contrib repos
    hyprland.url = "github:hyprwm/Hyprland/";
    xdg-portal-hyprland.url = "github:hyprwm/xdg-desktop-portal-hyprland";
    hyprpicker.url = "github:hyprwm/hyprpicker";
    hyprpaper.url = "github:hyprwm/hyprpaper";

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs-small";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs = {
        hyprland.follows = "hyprland";
      };
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://hyprland.cachix.org"
      "https://cache.privatevoid.net"
      "https://nyx.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg="
      "notashelf.cachix.org-1:VTTBFNQWbfyLuRzgm2I7AWSDJdqAa11ytLXHBhrprZk="
      "nyx.cachix.org-1:xH6G0MO9PrpeGe7mHBtj1WbNzmnXr7jId2mCiq6hipE="
    ];
  };
}
