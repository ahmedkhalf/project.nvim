_G.current_project_path = nil
local config = require("project_nvim.config")
local history = require("project_nvim.utils.history")
local M = {}

M.setup = config.setup
M.get_recent_projects = history.get_recent_projects
M.get_current_project_path = function()
  return _G.current_project_path
end

return M
