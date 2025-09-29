-- Custom commands for workspace management
vim.api.nvim_create_user_command("RestartTS", function()
  -- Restart TypeScript LSP
  vim.cmd("LspRestart tsserver")
  print("TypeScript LSP restarted")
end, { desc = "Restart TypeScript LSP" })

vim.api.nvim_create_user_command("TSInfo", function()
  -- Show TypeScript LSP info
  local clients = vim.lsp.get_clients({ name = "tsserver" })
  if #clients > 0 then
    local client = clients[1]
    print("TypeScript LSP Info:")
    print("  Root Directory: " .. (client.config.root_dir or "Not set"))
    print("  Workspace Folders: " .. vim.inspect(client.workspace_folders or {}))
    print("  Settings: " .. vim.inspect(client.config.settings or {}))
  else
    print("TypeScript LSP not running")
  end
end, { desc = "Show TypeScript LSP information" })

vim.api.nvim_create_user_command("WorkspaceInfo", function()
  -- Show workspace information
  local cwd = vim.fn.getcwd()
  print("Current Directory: " .. cwd)
  
  -- Check for workspace indicators
  local indicators = {
    "package.json",
    "yarn.lock",
    "tsconfig.json",
    ".pnp.cjs",
    ".git",
  }
  
  print("Workspace Indicators:")
  for _, indicator in ipairs(indicators) do
    local path = cwd .. "/" .. indicator
    if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
      print("  ✓ " .. indicator)
    else
      print("  ✗ " .. indicator)
    end
  end
end, { desc = "Show workspace information" })

vim.api.nvim_create_user_command("SetWorkspaceRoot", function(opts)
  -- Manually set workspace root for TypeScript LSP
  local path = opts.args or vim.fn.getcwd()
  local clients = vim.lsp.get_clients({ name = "tsserver" })
  
  if #clients > 0 then
    local client = clients[1]
    -- Change to the specified directory
    vim.cmd("cd " .. path)
    print("Changed to: " .. path)
    -- Restart the LSP
    vim.cmd("LspRestart tsserver")
    print("TypeScript LSP restarted with new root: " .. path)
  else
    print("TypeScript LSP not running")
  end
end, { desc = "Set workspace root for TypeScript LSP", nargs = "?" })