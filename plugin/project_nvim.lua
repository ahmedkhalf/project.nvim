if vim.fn.has("nvim-0.5") == 0 then
  return
end

if vim.g.loaded_project_nvim ~= nil then
  return
end

vim.cmd [[
let s:save_cpo = &cpo
set cpo&vim
]]

require("project_nvim")

vim.cmd [[
let &cpo = s:save_cpo
unlet s:save_cpo
]]

vim.g.loaded_project_nvim = 1
