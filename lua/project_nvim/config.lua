local M = {}

M.options = {}

local defaults = {
  -- No defaults till now
}

M.setup = function (options)
  M.options = vim.tbl_deep_extend("force", defaults, options or {})
end

return M
