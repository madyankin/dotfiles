return {
  -- LSP keymaps
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              diagnostics = { globals = { 'vim' } },
            },
          },
        },
        ruby_ls = {},
        gopls = {},
      },
    },
  },
}