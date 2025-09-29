return {
  -- Workspace-specific configuration for yarn workspaces
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsserver = {
          settings = {
            typescript = {
              format = { indentSize = 2 },
              preferences = {
                includePackageJsonAutoImports = "auto",
                allowIncompleteCompletions = true,
                allowRenameOfImportPath = true,
              },
              workspaceSymbols = {
                scope = "allOpenProjects",
              },
            },
            javascript = {
              format = { indentSize = 2 },
              preferences = {
                includePackageJsonAutoImports = "auto",
                allowIncompleteCompletions = true,
                allowRenameOfImportPath = true,
              },
              workspaceSymbols = {
                scope = "allOpenProjects",
              },
            },
          },
          -- Enhanced root directory detection for yarn workspaces
          root_dir = function(fname)
            local root_files = {
              "package.json",
              "tsconfig.json",
              "jsconfig.json",
              ".git",
              "yarn.lock",
              ".pnp.cjs",
            }
            
            -- First try to find workspace root
            local workspace_root = require("lspconfig.util").root_pattern(unpack(root_files))(fname)
            if workspace_root then
              return workspace_root
            end
            
            -- Fallback to git root
            return require("lspconfig.util").find_git_ancestor(fname)
          end,
          -- Enable workspace-wide features
          init_options = {
            preferences = {
              includePackageJsonAutoImports = "auto",
            },
          },
          -- Force single file mode for better yarn workspace support
          single_file_support = false,
          -- Enable all features
          capabilities = {
            workspace = {
              workspaceFolders = true,
            },
          },
        },
      },
    },
  },

  -- Project-specific configuration loader
  {
    "ahmedkhalf/project.nvim",
    config = function()
      require("project_nvim").setup({
        -- Manual mode: don't automatically change directory
        manual_mode = false,
        -- Detection methods
        detection_methods = { "pattern", "lsp" },
        -- Patterns to detect project root
        patterns = {
          ".git",
          "package.json",
          "tsconfig.json",
          "yarn.lock",
          ".pnp.cjs",
        },
        -- Show hidden files in telescope
        show_hidden = true,
        -- Silent mode
        silent_chdir = false,
        -- Scope directory
        scope_chdir = "global",
        -- Data path
        datapath = vim.fn.stdpath("data"),
      })
    end,
  },

  -- Workspace-aware file navigation
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      defaults = {
        file_ignore_patterns = {
          "node_modules/",
          ".yarn/",
          ".git/",
          "dist/",
          "build/",
        },
      },
    },
  },
}