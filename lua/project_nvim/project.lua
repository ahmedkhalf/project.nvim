local config = require("project_nvim.config")
local M = {}

-- Internal states
M.attached_lsp = false
M.last_dir = nil

function M.find_lsp_root()
  -- Get lsp client for current buffer
  -- Returns nil or string
  local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
  local clients = vim.lsp.buf_get_clients()
  if next(clients) == nil then
    return nil
  end

  for _, client in pairs(clients) do
    local filetypes = client.config.filetypes
    if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
      return client.config.root_dir
    end
  end

  return nil
end

---@diagnostic disable-next-line: unused-local
local on_attach_lsp = function(client, bufnr)
  M.on_buf_enter() -- Recalculate root dir after lsp attaches
end

function M.attach_to_lsp()
  if M.attached_lsp then
    return
  end

  local _start_client = vim.lsp.start_client
  vim.lsp.start_client = function(lsp_config)
    if lsp_config.on_attach == nil then
      lsp_config.on_attach = on_attach_lsp
    else
      local _on_attach = lsp_config.on_attach
      lsp_config.on_attach = function(client, bufnr)
        on_attach_lsp(client, bufnr)
        _on_attach(client, bufnr)
      end
    end
    return _start_client(lsp_config)
  end

  M.attached_lsp = true
end

function M.set_pwd(dir)
  if dir ~= nil then
    if M.last_dir ~= dir then
      vim.api.nvim_set_current_dir(dir)

      -- NvimTree integration
      local status, nvim_tree = pcall(require, "nvim-tree.lib")
      if status then
        pcall(nvim_tree.change_dir, dir)
      end

      M.last_dir = dir
      print("Set PWD to", dir)
    end
    return true
  end

  return false
end

function M.on_buf_enter()
  for _, detection_method in ipairs(config.options.detection_methods) do
    if detection_method == "lsp" then
      if M.set_pwd(M.find_lsp_root()) then
        return
      end
    end
  end
end

function M.init()
  vim.cmd('autocmd BufEnter * lua require("project_nvim.project").on_buf_enter()')

  for _, detection_method in ipairs(config.options.detection_methods) do
    if detection_method == "lsp" then
      M.attach_to_lsp()
    end
  end
end

return M
