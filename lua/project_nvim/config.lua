local M = {}

---@class ProjectOptions
local defaults = {
  -- Manual mode doesn't automatically change your root directory, so you have
  -- the option to manually do so using `:ProjectRoot` command.
  manual_mode = false,

  -- Methods of detecting the root directory. **"lsp"** uses the native neovim
  -- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
  -- order matters: if one is not detected, the other is used as fallback. You
  -- can also delete or rearangne the detection methods.
  detection_methods = { "lsp", "pattern" },

  -- All the patterns used to detect root dir, when **"pattern"** is in
  -- detection_methods
  patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json" },

  -- Table of lsp clients to ignore by name
  -- eg: { "efm", ... }
  ignore_lsp = {},

  -- Show hidden files in telescope
  show_hidden = false,

  -- When set to false, you will get a message when project.nvim changes your
  -- directory.
  silent_chdir = true,

  -- Path where project.nvim will store the project history for use in
  -- telescope
  datapath = vim.fn.stdpath("data"),
}

---@type ProjectOptions
M.options = {}

M.setup = function (options)
  M.options = vim.tbl_deep_extend("force", defaults, options or {})
  require("project_nvim.utils.path").init()
  require("project_nvim.project").init()
end

return M
