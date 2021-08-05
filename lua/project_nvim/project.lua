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

function M.debug_write(string)
  local file = io.open("/home/ahmedk/Documents/Projects/Nvim/project.nvim/debug", "a")
  file:write(string)
  file:close()
end

function M.find_pattern_root()
  -- Sacrificing readability for speed :(
  -- Good luck

  local function find(file_dir)
    vim.loop.fs_opendir(file_dir, function(err_open, dir)
      if err_open ~= nil then
        return
      end

      local function read(err_read, entries)
        if err_read ~= nil then
          return
        end

        if entries ~= nil then
          for _, entry in ipairs(entries) do
            for _, pattern in ipairs(config.options.patterns) do
              if entry.name:match(pattern) == entry.name then

                -- TODO: stop using timer
                local timer = vim.loop.new_timer()
                timer:start(0, 0, vim.schedule_wrap(function()
                  M.set_pwd(file_dir)
                end))
                return
              end
            end
          end
          dir:readdir(read)
        else
          dir:closedir()

          -- TODO: Stop using vim.fn as well as timer
          local timer = vim.loop.new_timer()
          timer:start(0, 0, vim.schedule_wrap(function()
            local parent = vim.fn.fnamemodify(file_dir, ':h')
            if parent == file_dir then
              return
            end
            find(parent)
          end))
        end
      end

      dir:readdir(read)
    end, 50)
  end

  find(vim.fn.expand('%:p:h', true))
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

      if config.options.silent_chdir == false then
        print("Set CWD to", dir)
      end
    end
    return true
  end

  return false
end

function M.find_root_dir()
  for _, detection_method in ipairs(config.options.detection_methods) do
    if detection_method == "lsp" then
      local root = M.find_lsp_root()
      if root ~= nil then
        return root
      end
    elseif detection_method == "pattern" then
      M.find_pattern_root()
    end
  end

  return nil
end

function M.on_buf_enter()
  M.set_pwd(M.find_root_dir())
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
