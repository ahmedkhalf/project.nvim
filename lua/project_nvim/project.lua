local config = require("project_nvim.config")
local history = require("project_nvim.utils.history")
local glob = require("project_nvim.utils.globtopattern")
local path = require("project_nvim.utils.path")
local uv = vim.loop
local M = {}

-- Internal states
M.attached_lsp = false
M.last_project = nil

function M.find_lsp_root()
  -- Get lsp client for current buffer
  -- Returns nil or string
  local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
  local clients = vim.lsp.buf_get_clients()
  if next(clients) == nil then
    return nil
  end

  for _, client in pairs(clients) do
    local filetypes = client.config.filetypes
    if filetypes and vim.tbl_contains(filetypes, buf_ft) then
      if not vim.tbl_contains(config.options.ignore_lsp, client.name) then
        return client.config.root_dir, client.name
      end
    end
  end

  return nil
end

function M.find_pattern_root()
  local search_dir = vim.fn.expand("%:p:h", true)
  if vim.fn.has("win32") > 0 then
    search_dir = search_dir:gsub("\\", "/")
  end

  local last_dir_cache = ""
  local curr_dir_cache = {}

  local function get_parent(path)
    path = path:match("^(.*)/")
    if path == "" then
      path = "/"
    end
    return path
  end

  local function get_files(file_dir)
    last_dir_cache = file_dir
    curr_dir_cache = {}

    local dir = uv.fs_scandir(file_dir)
    if dir == nil then
      return
    end

    while true do
      local file = uv.fs_scandir_next(dir)
      if file == nil then
        return
      end

      table.insert(curr_dir_cache, file)
    end
  end

  local function is(dir, identifier)
    dir = dir:match(".*/(.*)")
    return dir == identifier
  end

  local function sub(dir, identifier)
    local path = get_parent(dir)
    while true do
      if is(path, identifier) then
        return true
      end
      local current = path
      path = get_parent(path)
      if current == path then
        return false
      end
    end
  end

  local function child(dir, identifier)
    local path = get_parent(dir)
    return is(path, identifier)
  end

  local function has(dir, identifier)
    if last_dir_cache ~= dir then
      get_files(dir)
    end
    local pattern = glob.globtopattern(identifier)
    for _, file in ipairs(curr_dir_cache) do
      if file:match(pattern) ~= nil then
        return true
      end
    end
    return false
  end

  local function match(dir, pattern)
    local first_char = pattern:sub(1, 1)
    if first_char == "=" then
      return is(dir, pattern:sub(2))
    elseif first_char == "^" then
      return sub(dir, pattern:sub(2))
    elseif first_char == ">" then
      return child(dir, pattern:sub(2))
    else
      return has(dir, pattern)
    end
  end

  -- breadth-first search
  while true do
    for _, pattern in ipairs(config.options.patterns) do
      local exclude = false
      if pattern:sub(1, 1) == "!" then
        exclude = true
        pattern = pattern:sub(2)
      end
      if match(search_dir, pattern) then
        if exclude then
          break
        else
          return search_dir, "pattern " .. pattern
        end
      end
    end

    local parent = get_parent(search_dir)
    if parent == search_dir or parent == nil then
      return nil
    end

    search_dir = parent
  end
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

function M.set_pwd(dir, method)
  if dir ~= nil then
    M.last_project = dir
    table.insert(history.session_projects, dir)

    if vim.fn.getcwd() ~= dir then
      local scope_chdir = config.options.scope_chdir
      if scope_chdir == 'global' then
        vim.api.nvim_set_current_dir(dir)
      elseif scope_chdir == 'tab' then
        vim.cmd('tcd ' .. dir)
      elseif scope_chdir == 'win' then
        vim.cmd('lcd ' .. dir)
      else
        return
      end

      if config.options.silent_chdir == false then
        vim.notify("Set CWD to " .. dir .. " using " .. method)
      end
    end
    return true
  end

  return false
end

function M.get_project_root()
  -- returns project root, as well as method
  for _, detection_method in ipairs(config.options.detection_methods) do
    if detection_method == "lsp" then
      local root, lsp_name = M.find_lsp_root()
      if root ~= nil then
        return root, '"' .. lsp_name .. '"' .. " lsp"
      end
    elseif detection_method == "pattern" then
      local root, method = M.find_pattern_root()
      if root ~= nil then
        return root, method
      end
    end
  end
end

function M.is_file()
  local buf_type = vim.api.nvim_buf_get_option(0, "buftype")

  local whitelisted_buf_type = { "", "acwrite" }
  local is_in_whitelist = false
  for _, wtype in ipairs(whitelisted_buf_type) do
    if buf_type == wtype then
      is_in_whitelist = true
      break
    end
  end
  if not is_in_whitelist then
    return false
  end

  return true
end

function M.on_buf_enter()
  if vim.v.vim_did_enter == 0 then
    return
  end

  if not M.is_file() then
    return
  end

  local current_dir = vim.fn.expand("%:p:h", true)
  if not path.exists(current_dir) or path.is_excluded(current_dir) then
    return
  end

  local root, method = M.get_project_root()
  M.set_pwd(root, method)
end

function M.add_project_manually()
  local current_dir = vim.fn.expand("%:p:h", true)
  M.set_pwd(current_dir, 'manual')
end

function M.init()
  local autocmds = {}
  if not config.options.manual_mode then
    autocmds[#autocmds + 1] = 'autocmd VimEnter,BufEnter * ++nested lua require("project_nvim.project").on_buf_enter()'

    if vim.tbl_contains(config.options.detection_methods, "lsp") then
      M.attach_to_lsp()
    end
  end

  vim.cmd([[
    command! ProjectRoot lua require("project_nvim.project").on_buf_enter()
    command! AddProject lua require("project_nvim.project").add_project_manually()
  ]])

  autocmds[#autocmds + 1] =
    'autocmd VimLeavePre * lua require("project_nvim.utils.history").write_projects_to_history()'

  vim.cmd([[augroup project_nvim
            au!
  ]])
  for _, value in ipairs(autocmds) do
    vim.cmd(value)
  end
  vim.cmd("augroup END")

  history.read_projects_from_history()
end

return M
