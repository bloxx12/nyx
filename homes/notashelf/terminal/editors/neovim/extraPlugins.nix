{pkgs, ...}: let
  inherit (pkgs.vimPlugins) friendly-snippets aerial-nvim nvim-surround undotree mkdir-nvim ssr-nvim direnv-vim;
  pluginSources = import ./pluginSources.nix {inherit pkgs;};
in {
  # plugins that are pulled from nixpkgs
  direnv = {package = direnv-vim;};
  friendly-snippets = {package = friendly-snippets;};
  mkdir-nvim = {package = mkdir-nvim;};
  aerial = {
    package = aerial-nvim;
    setup = "require('aerial').setup {}";
  };

  nvim-surround = {
    package = nvim-surround;
    setup = "require('nvim-surround').setup {}";
  };

  undotree = {
    package = undotree;
    setup = ''
      vim.g.undotree_ShortIndicators = true
      vim.g.undotree_TreeVertShape = '│'
    '';
  };

  ssr-nvim = {
    package = ssr-nvim;
    setup = "require('ssr').setup {}";
  };

  # plugins that are built from their sources
  regexplainer = {package = pluginSources.regexplainer;};
  data-view = {
    package = pluginSources.data-viewer-nvim;
    setup = ''
      -- open data files in data-viewer.nvim
      vim.api.nvim_exec([[
        autocmd BufReadPost,BufNewFile *.sqlite,*.csv,*.tsv DataViewer
      ]], false)


      -- keybinds
      vim.api.nvim_set_keymap('n', '<leader>dv', ':DataViewer<CR>', {noremap = true})
      vim.api.nvim_set_keymap('n', '<leader>dvn', ':DataViewerNextTable<CR>', {noremap = true})
      vim.api.nvim_set_keymap('n', '<leader>dvp', ':DataViewerPrevTable<CR>', {noremap = true})
      vim.api.nvim_set_keymap('n', '<leader>dvc', ':DataViewerClose<CR>', {noremap = true})
    '';
  };

  slides-nvim = {
    package = pluginSources.slides-nvim;
    setup = "require('slides').setup {}";
  };

  hmts = {
    package = pluginSources.hmts;
    after = ["treesitter"];
  };

  smart-splits = {
    package = pluginSources.smart-splits;
    setup = "require('smart-splits').setup {}";
  };

  specs-nvim = {
    package = pluginSources.specs-nvim;
    setup = ''
      require('specs').setup {
        show_jumps = true,
        popup = {
          delay_ms = 0,
          inc_ms = 15,
          blend = 15,
          width = 10,
          winhl = "PMenu",
          fader = require('specs').linear_fader,
          resizer = require('specs').shrink_resizer
        },

        ignore_filetypes = {'NvimTree', 'undotree'},

        ignore_buftypes = {nofile = true},
      }

      -- toggle specs using the <C-b> keybind
      vim.api.nvim_set_keymap('n', '<C-b>', ':lua require("specs").show_specs()', { noremap = true, silent = true })

      -- bind specs to navigation keys
      vim.api.nvim_set_keymap('n', 'n', 'n:lua require("specs").show_specs()<CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', 'N', 'N:lua require("specs").show_specs()<CR>', { noremap = true, silent = true })
    '';
  };
}
