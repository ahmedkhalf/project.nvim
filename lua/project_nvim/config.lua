local M = {}

---@class ProjectOptions
local defaults = {
  -- manual_mode = false,

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

  -- When set to false, you will get a message when project.nvim chnages your
  -- directory.
  silent_chdir = true,
}

---@type ProjectOptions
M.options = {}

M.setup = function (options)
  M.options = vim.tbl_deep_extend("force", defaults, options or {})
  require("project_nvim.project").init()
end

return M
