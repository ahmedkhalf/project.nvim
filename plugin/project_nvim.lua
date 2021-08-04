if vim.fn.has("nvim-0.5") == 0 then
  return
end

if vim.g.loaded_project_nvim ~= nil then
  return
end

require("project_nvim")

vim.g.loaded_project_nvim = 1
