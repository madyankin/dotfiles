-- LSP keymaps are handled by LazyVim

return {
  { 'folke/lazy.nvim', version = false },

  {
    'numToStr/Comment.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = true,
  },

  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('gitsigns').setup()
    end,
  },

  {
    'nvim-lua/plenary.nvim',
  },

  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = { 'nvim-lua/plenary.nvim' },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = {
        'bash',
        'go',
        'javascript',
        'json',
        'lua',
        'markdown',
        'ruby',
        'tsx',
        'typescript',
        'yaml',
        -- Additional TypeScript/JavaScript parsers
        'jsdoc',
        'jsonc',
        'vue',
        'svelte',
        'astro',
        'prisma',
        'graphql',
        'dockerfile',
        'gitignore',
        'gitcommit',
        'git_config',
        'git_rebase',
      },
      indent = {
        enable = false, -- Disable treesitter-based indentation
      },
    },
  },

  {
    'mason-org/mason.nvim',
    build = ':MasonUpdate',
    config = function()
      require('mason').setup()
    end,
  },


  -- LSP configuration is handled by LazyVim extras
  -- Custom LSP servers can be configured in separate files

  -- Completion is handled by LazyVim extras

  -- TypeScript support is imported in lazy.lua


  -- Yarn workspace support
  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    event = { "BufRead package.json" },
    config = function()
      require("package-info").setup({
        colors = {
          up_to_date = "#3C4048", -- Text color for up to date package version
          outdated = "#d19a66", -- Text color for outdated package version
        },
        icons = {
          enable = true, -- Enable package icons
          style = {
            up_to_date = "|  ", -- Icon for up to date package
            outdated = "|󰄬 ", -- Icon for outdated package
          },
        },
        autostart = true, -- Automatically start package info
        hide_up_to_date = false, -- Hide up to date packages
        hide_unstable_versions = false, -- Hide unstable versions from versions list
      })
    end,
  },
}
