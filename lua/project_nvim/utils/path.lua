local uv = vim.loop
local M = {}

M.datapath = vim.fn.stdpath("data") -- directory
M.projectpath = M.datapath .. "/project_nvim" -- directory
M.historyfile = M.projectpath .. "/project_history" -- file

function M.init()
  M.datapath = require("project_nvim.config").options.datapath
  M.projectpath = M.datapath .. "/project_nvim" -- directory
  M.historyfile = M.projectpath .. "/project_history" -- file
end

function M.create_scaffolding(callback)
  if callback ~= nil then -- async
    uv.fs_mkdir(M.projectpath, 448, callback)
  else -- sync
    uv.fs_mkdir(M.projectpath, 448)
  end
end

return M
