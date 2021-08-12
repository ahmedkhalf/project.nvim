local path = require("project_nvim.utils.path")
local uv = vim.loop
local M = {}

M.recent_projects = nil -- projects from previous neovim sessions
M.session_projects = {} -- projects from current neovim session

local function open_history(mode, callback)
  if callback ~= nil then -- async
    path.create_scaffolding(function(_, _)
      uv.fs_open(path.historyfile, mode, 438, callback)
    end)
  else -- sync
    path.create_scaffolding()
    return uv.fs_open(path.historyfile, mode, 438)
  end
end

local function dir_exists(dir)
  local stat = uv.fs_stat(dir)
  if stat ~= nil and stat.type == "directory" then
    return true
  end
  return false
end

local function delete_duplicates(tbl)
  local cache_dict = {}
  for _, v in ipairs(tbl) do
    if cache_dict[v] == nil then
      cache_dict[v] = 1
    else
      cache_dict[v] = cache_dict[v] + 1
    end
  end

  local res = {}
  for _, v in ipairs(tbl) do
    if cache_dict[v] == 1 then
      table.insert(res, v)
    else
      cache_dict[v] = cache_dict[v] - 1
    end
  end
  return res
end

local function deserialize_history(history_data)
  -- split data to table
  local projects = {}
  for s in history_data:gmatch("[^\r\n]+") do
    if dir_exists(s) then
      table.insert(projects, s)
    end
  end

  projects = delete_duplicates(projects)

  M.recent_projects = projects
end

function M.read_projects_from_history()
  open_history("r", function(_, fd)
    if fd ~= nil then
      uv.fs_fstat(fd, function(_, stat)
        if stat ~= nil then
          uv.fs_read(fd, stat.size, nil, function(_, data)
            uv.fs_close(fd, function(_, _)
            end)
            deserialize_history(data)
          end)
        end
      end)
    end
  end)
end

local function sanitize_projects()
  local tbl = {}
  if M.recent_projects ~= nil then
    vim.list_extend(tbl, M.recent_projects)
    vim.list_extend(tbl, M.session_projects)
  else
    tbl = M.session_projects
  end

  tbl = delete_duplicates(tbl)

  local real_tbl = {}
  for _, dir in ipairs(tbl) do
    if dir_exists(dir) then
      table.insert(real_tbl, dir)
    end
  end

  return real_tbl
end

function M.get_recent_projects()
  return sanitize_projects()
end

function M.write_projects_to_history()
  -- Unlike read projects, write projects is synchronous
  -- because it runs when vim ends
  local file = open_history("w")

  if file ~= nil then
    local res = sanitize_projects()

    -- Trim table to last 100 entries
    local len_res = #res
    local tbl_out = {}
    if #res > 100 then
      tbl_out = vim.list_slice(res, len_res - 100, len_res)
    else
      tbl_out = res
    end

    -- Transform table to string
    local out = ""
    for _, v in ipairs(tbl_out) do
      out = out .. v .. "\n"
    end

    -- Write string out to file and close
    uv.fs_write(file, out)
    uv.fs_close(file)
  end
end

return M
