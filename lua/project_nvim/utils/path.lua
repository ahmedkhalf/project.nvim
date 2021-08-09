local M = {}

M.datapath = vim.fn.stdpath("data")
M.projectpath = M.datapath .. "/project_nvim"
M.historypath = M.projectpath .. "/project_history"

return M
