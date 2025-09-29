local function set_lsp_keymaps(bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
  map('n', 'gr', vim.lsp.buf.references, 'Go to references')
  map('n', 'K', vim.lsp.buf.hover, 'Hover docs')
  map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
  map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
  map('n', '<leader>fd', vim.diagnostic.open_float, 'Line diagnostics')
  map('n', '[d', vim.diagnostic.goto_prev, 'Prev diagnostic')
  map('n', ']d', vim.diagnostic.goto_next, 'Next diagnostic')
  map('n', '<leader>fo', function()
    vim.lsp.buf.format({ async = true })
  end, 'Format buffer')
end

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

  {
    'mason-org/mason-lspconfig.nvim',
    dependencies = { 'mason-org/mason.nvim' },
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'mason-org/mason-lspconfig.nvim',
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      local capabilities = vim.tbl_deep_extend(
        'force',
        vim.lsp.protocol.make_client_capabilities(),
        require('cmp_nvim_lsp').default_capabilities()
      )

      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              diagnostics = { globals = { 'vim' } },
            },
          },
        },
        ruby_ls = {},
        tsserver = {
          settings = {
            javascript = { format = { indentSize = 2 } },
            typescript = { format = { indentSize = 2 } },
          },
        },
        gopls = {},
      }

      local mason_lspconfig = require('mason-lspconfig')
      mason_lspconfig.setup({ ensure_installed = vim.tbl_keys(servers) })

      mason_lspconfig.setup_handlers({
        function(server_name)
          local server_opts = vim.tbl_deep_extend(
            'force',
            {
              capabilities = capabilities,
              on_attach = set_lsp_keymaps,
            },
            servers[server_name] or {}
          )

          require('lspconfig')[server_name].setup(server_opts)
        end,
      })
    end,
  },

  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'saadparwaiz1/cmp_luasnip',
      'L3MON4D3/LuaSnip',
      'rafamadriz/friendly-snippets',
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      require('luasnip.loaders.from_vscode').lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
          { name = 'path' },
        }),
      })
    end,
  },
}
