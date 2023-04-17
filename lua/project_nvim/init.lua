local config = require("project_nvim.config")
local project = require("project_nvim.project")
local history = require("project_nvim.utils.history")
local M = {}

M.setup = config.setup
M.get_recent_projects = history.get_recent_projects
M.get_project_root = project.get_project_root

return M
