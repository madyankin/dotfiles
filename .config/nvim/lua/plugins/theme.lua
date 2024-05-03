return {
  {
    "projekt0n/github-nvim-theme",

    lazy = false,
    priority = 1000,

    config = function()
      require("github-theme").setup({})
      vim.cmd("colorscheme github_dark_dimmed")
      vim.cmd("hi! Normal guibg=NONE ctermbg=NONE")
      vim.cmd("hi! NonText guibg=NONE ctermbg=NONE")
    end,
  },

  {
    "f-person/auto-dark-mode.nvim",

    config = {
      update_interval = 1000,

      set_dark_mode = function()
        vim.api.nvim_set_option("background", "dark")
        vim.cmd("colorscheme github_dark_dimmed")
        vim.cmd("hi! Normal guibg=NONE ctermbg=NONE")
        vim.cmd("hi! NonText guibg=NONE ctermbg=NONE")
      end,

      set_light_mode = function()
        vim.api.nvim_set_option("background", "light")
        vim.cmd("colorscheme github_light_default")
        vim.cmd("hi! Normal guibg=NONE ctermbg=NONE")
        vim.cmd("hi! NonText guibg=NONE ctermbg=NONE")
      end,
    },
  },

  {
    "xiyaowong/transparent.nvim",
    config = function()
      require("transparent").setup({
        extra_groups = {
          "NeoTreeNormal",
          "NeoTreeNormalNC",
          "NormalFloat",
        },
      })
    end,
  },
}
