local config = require("project_nvim.config")
local project = require("project_nvim.project")
local path = require("project_nvim.utils.path")
local escape = vim.fn.fnameescape
local M = {}

local function delete_all_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local buf_type = vim.api.nvim_buf_get_option(buf, "buftype")
    local buf_name = vim.api.nvim_buf_get_name(buf)

    local whitelisted_buf_type = { "", "acwrite" }
    local is_in_whitelist = false
    for _, wtype in ipairs(whitelisted_buf_type) do
      if buf_type == wtype then
        is_in_whitelist = true
        break
      end
    end
    if not is_in_whitelist then
      vim.api.nvim_buf_delete(buf, {force=true})
    end

    if buf_name == "" then
      vim.api.nvim_buf_delete(buf, {force=true})
    end
  end
end

function M.save()
  path.create_scaffolding()
  if project.last_project == vim.fn.getcwd() then
    local tmp_opt = vim.o.sessionoptions
    vim.o.sessionoptions = table.concat(config.options.session_options, ",")

    delete_all_buffers()

    local filename = project.last_project:gsub("/", "%%") .. ".vim"
    filename = path.sessionpath .. "/" .. filename
    vim.cmd("mks! " .. escape(filename))

    vim.o.sessionoptions = tmp_opt
  end
end

local function get_last_sesh()
  local sessions = vim.fn.glob(path.sessionpath .. "/" .. "*.vim", true, true)
  table.sort(sessions, function(a, b)
    return vim.loop.fs_stat(a).mtime.sec > vim.loop.fs_stat(b).mtime.sec
  end)
  return sessions[1]
end

function M.load(dir)
  local filename = dir
  if filename == nil then
    filename = get_last_sesh()
    if filename == nil then
      return
    end
  else
    filename = filename:gsub("/", "%%") .. ".vim"
    filename = path.sessionpath .. "/" .. filename
  end

  if vim.fn.filereadable(filename) ~= 0 then
    vim.cmd("source " .. escape(filename))
  end
end

return M
