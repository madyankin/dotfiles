return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        solargraph = {},
      },
    },
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "solargraph",
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "ruby" },
    },
  },
}
