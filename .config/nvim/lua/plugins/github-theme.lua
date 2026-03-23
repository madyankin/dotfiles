return {
  -- GitHub theme (used for light mode)
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({
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
        groups = {
          all = {
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
            FloatBorder = { bg = "NONE" },
            TelescopeNormal = { bg = "NONE" },
            TelescopeBorder = { bg = "NONE" },
            TelescopePromptNormal = { bg = "NONE" },
            TelescopePromptBorder = { bg = "NONE" },
            TelescopeResultsNormal = { bg = "NONE" },
            TelescopeResultsBorder = { bg = "NONE" },
            TelescopePreviewNormal = { bg = "NONE" },
            TelescopePreviewBorder = { bg = "NONE" },
            NvimTreeNormal = { bg = "NONE" },
            NvimTreeNormalNC = { bg = "NONE" },
            NvimTreeEndOfBuffer = { bg = "NONE" },
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

  -- One Dark theme (used for dark mode)
  {
    "navarasu/onedark.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("onedark").setup({
        style = "dark",
        transparent = true,
        term_colors = true,
        ending_tildes = false,
        cmp_itemkind_reverse = false,
        toggle_style_key = nil,
        code_style = {
          comments = "italic",
          keywords = "bold",
          functions = "italic",
          strings = "none",
          variables = "bold",
        },
        lualine = {
          transparent = true,
        },
        colors = {},
        highlights = {
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
          FloatBorder = { bg = "NONE" },
          TelescopeNormal = { bg = "NONE" },
          TelescopeBorder = { bg = "NONE" },
          TelescopePromptNormal = { bg = "NONE" },
          TelescopePromptBorder = { bg = "NONE" },
          TelescopeResultsNormal = { bg = "NONE" },
          TelescopeResultsBorder = { bg = "NONE" },
          TelescopePreviewNormal = { bg = "NONE" },
          TelescopePreviewBorder = { bg = "NONE" },
          NvimTreeNormal = { bg = "NONE" },
          NvimTreeNormalNC = { bg = "NONE" },
          NvimTreeEndOfBuffer = { bg = "NONE" },
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
        },
      })
    end,
  },

  -- Configure LazyVim to use onedark as default (dark mode)
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onedark",
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
        update_interval = 1000,
        set_dark_mode = function()
          vim.api.nvim_set_option("background", "dark")
          vim.cmd("colorscheme onedark")
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
