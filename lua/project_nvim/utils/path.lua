local uv = vim.loop
local M = {}

M.datapath = vim.fn.stdpath("data") -- directory
M.projectpath = M.datapath .. "/project_nvim" -- directory
M.historyfile = M.projectpath .. "/project_history" -- file
M.sessionpath = M.projectpath .. "/project_sessions" -- directory

function M.create_scaffolding(callback)
  if callback ~= nil then -- async
    uv.fs_mkdir(M.projectpath, 448, function(_, _)
      uv.fs_mkdir(M.sessionpath, 448, callback)
    end)
  else -- sync
    uv.fs_mkdir(M.projectpath, 448)
    uv.fs_mkdir(M.sessionpath, 448)
  end
end

return M
