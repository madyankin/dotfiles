return {
  -- Explicitly disable indent-blankline plugin (LazyVim loads this by default)
  {
    "lukas-reineke/indent-blankline.nvim",
    enabled = false,
  },
  -- Also disable snacks indent functionality
  {
    "snacks.nvim",
    opts = {
      indent = { enabled = false },
    },
  },
}