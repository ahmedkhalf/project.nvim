local M = {}

M.options = {}

local defaults = {
  -- manual_mode = false,
  detection_methods = { "lsp" }
}

M.setup = function (options)
  M.options = vim.tbl_deep_extend("force", defaults, options or {})
  require("project_nvim.project").init()
end

return M
