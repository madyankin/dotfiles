return {
  -- TypeScript configuration override for LazyVim with yarn workspace support
  {
    "jose-elias-alvarez/typescript.nvim",
    opts = {
      server = {
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
      },
    },
  },
}