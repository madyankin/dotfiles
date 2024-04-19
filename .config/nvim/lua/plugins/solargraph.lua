return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        solargraph = {
          cmd = { os.getenv("HOME") .. "/.asdf/shims/solargraph", "stdio" },
          root_dir = nvim_lsp.util.root_pattern("Gemfile", ".git", "."),
          settings = {
            solargraph = {
              autoformat = true,
              completion = true,
              diagnostic = true,
              folding = true,
              references = true,
              rename = true,
              symbols = true,
            },
          },
        },
      },
    },
  },
}
