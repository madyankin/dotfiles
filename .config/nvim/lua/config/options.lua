-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Enable transparency
vim.opt.termguicolors = true
vim.opt.background = "dark" -- Will be overridden by auto-dark-mode

-- Additional transparency settings
vim.opt.pumblend = 10 -- Make popup menu slightly transparent
vim.opt.winblend = 10 -- Make floating windows slightly transparent

-- Disable indentation guides
vim.opt.list = false
vim.opt.listchars = {}

-- Additional settings to ensure indentation guides are disabled
vim.opt.showbreak = ""
vim.opt.fillchars = {
  fold = " ",
  foldopen = " ",
  foldsep = " ",
  foldclose = " ",
}

-- Disable any potential indent guides from treesitter or other sources
vim.opt.conceallevel = 0
vim.opt.concealcursor = ""

-- Force disable indentation guides after plugins load
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.opt.list = false
    vim.opt.listchars = {}
    vim.opt.showbreak = ""
  end,
})
