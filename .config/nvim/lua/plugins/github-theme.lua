return {
  -- GitHub theme plugin
  {
    "projekt0n/github-nvim-theme",
    lazy = false, -- load immediately
    priority = 1000, -- load before other plugins
    config = function()
      require("github-theme").setup({
        -- Enable transparent background
        options = {
          transparent = true,
          hide_end_of_buffer = true,
          hide_nc_statusline = true,
          styles = {
            comments = "italic",
            keywords = "bold",
            functions = "italic",
            variables = "bold",
          },
          darken = {
            sidebars = {
              list = { "qf", "vista_kind", "terminal", "packer" }
            }
          }
        },
        -- Override highlight groups for transparency
        groups = {
          all = {
            -- Make the background transparent for various UI elements
            Normal = { bg = "NONE" },
            NormalFloat = { bg = "NONE" },
            NormalNC = { bg = "NONE" },
            CursorLine = { bg = "NONE" },
            CursorLineNr = { bg = "NONE" },
            SignColumn = { bg = "NONE" },
            StatusLine = { bg = "NONE" },
            StatusLineNC = { bg = "NONE" },
            TabLine = { bg = "NONE" },
            TabLineFill = { bg = "NONE" },
            TabLineSel = { bg = "NONE" },
            WinBar = { bg = "NONE" },
            WinBarNC = { bg = "NONE" },
            -- Make floating windows transparent
            FloatBorder = { bg = "NONE" },
            -- Make telescope transparent
            TelescopeNormal = { bg = "NONE" },
            TelescopeBorder = { bg = "NONE" },
            TelescopePromptNormal = { bg = "NONE" },
            TelescopePromptBorder = { bg = "NONE" },
            TelescopeResultsNormal = { bg = "NONE" },
            TelescopeResultsBorder = { bg = "NONE" },
            TelescopePreviewNormal = { bg = "NONE" },
            TelescopePreviewBorder = { bg = "NONE" },
            -- Make nvim-tree transparent
            NvimTreeNormal = { bg = "NONE" },
            NvimTreeNormalNC = { bg = "NONE" },
            NvimTreeEndOfBuffer = { bg = "NONE" },
            -- Make bufferline transparent
            BufferLineFill = { bg = "NONE" },
            BufferLineBackground = { bg = "NONE" },
            BufferLineBufferVisible = { bg = "NONE" },
            BufferLineBufferSelected = { bg = "NONE" },
            -- Make lualine transparent
            lualine_a_normal = { bg = "NONE" },
            lualine_b_normal = { bg = "NONE" },
            lualine_c_normal = { bg = "NONE" },
            lualine_x_normal = { bg = "NONE" },
            lualine_y_normal = { bg = "NONE" },
            lualine_z_normal = { bg = "NONE" },
            lualine_a_insert = { bg = "NONE" },
            lualine_b_insert = { bg = "NONE" },
            lualine_c_insert = { bg = "NONE" },
            lualine_x_insert = { bg = "NONE" },
            lualine_y_insert = { bg = "NONE" },
            lualine_z_insert = { bg = "NONE" },
            lualine_a_visual = { bg = "NONE" },
            lualine_b_visual = { bg = "NONE" },
            lualine_c_visual = { bg = "NONE" },
            lualine_x_visual = { bg = "NONE" },
            lualine_y_visual = { bg = "NONE" },
            lualine_z_visual = { bg = "NONE" },
            lualine_a_replace = { bg = "NONE" },
            lualine_b_replace = { bg = "NONE" },
            lualine_c_replace = { bg = "NONE" },
            lualine_x_replace = { bg = "NONE" },
            lualine_y_replace = { bg = "NONE" },
            lualine_z_replace = { bg = "NONE" },
            lualine_a_command = { bg = "NONE" },
            lualine_b_command = { bg = "NONE" },
            lualine_c_command = { bg = "NONE" },
            lualine_x_command = { bg = "NONE" },
            lualine_y_command = { bg = "NONE" },
            lualine_z_command = { bg = "NONE" },
            lualine_a_inactive = { bg = "NONE" },
            lualine_b_inactive = { bg = "NONE" },
            lualine_c_inactive = { bg = "NONE" },
            lualine_x_inactive = { bg = "NONE" },
            lualine_y_inactive = { bg = "NONE" },
            lualine_z_inactive = { bg = "NONE" },
          }
        },
      })
    end,
  },

  -- Configure LazyVim to use GitHub theme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_dark_default", -- Default to dark theme
    },
  },

  -- Auto-switch theme based on system appearance
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local auto_dark_mode = require("auto-dark-mode")
      
      auto_dark_mode.setup({
        update_interval = 1000, -- Check for system theme changes every second
        set_dark_mode = function()
          vim.api.nvim_set_option("background", "dark")
          vim.cmd("colorscheme github_dark_default")
        end,
        set_light_mode = function()
          vim.api.nvim_set_option("background", "light")
          vim.cmd("colorscheme github_light_default")
        end,
      })
      
      auto_dark_mode.init()
    end,
  },
}