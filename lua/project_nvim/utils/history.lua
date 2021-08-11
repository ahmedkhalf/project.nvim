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

-- local function dir_exists(path)
-- here we can use uv.fs_stat
-- end

local function deserialize_history(history_data)
  local work_ctx = uv.new_work(function(data)
    ---@diagnostic disable-next-line: redefined-local
    local uv = require("luv")

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

    -- split data to table
    local projects = {}
    for s in data:gmatch("[^\r\n]+") do
      if dir_exists(s) then
        table.insert(projects, s)
      end
    end

    projects = delete_duplicates(projects)

    if #projects > 0 then
      return unpack(projects)
    end

    -- Must return something otherwise segmentation fault: #561 luv
    return nil
  end, function(...)
    local projects = {...}
    M.recent_projects = projects
  end)

  work_ctx:queue(history_data)
end

function M.read_projects_from_history()
  -- This function is asynchronous and multithreaded (deserialize_history)
  -- therefore it should not tax the vim startup time
  open_history("r", function(_, fd)
    if fd ~= nil then
      uv.fs_fstat(fd, function(_, stat)
        if stat ~= nil then
          uv.fs_read(fd, stat.size, nil, function(_, data)
            deserialize_history(data)
            uv.fs_close(fd, function(_, _)
            end)
          end)
        end
      end)
    end
  end)
end

local function sanitize_projects()
    M.recent_projects = M.recent_projects or {}

    -- Merge recent_projects and session_projects in tbl
    local tbl = {}
    local n = 0
    for _, v in ipairs(M.recent_projects) do n=n+1; tbl[n]=v end
    for _, v in ipairs(M.session_projects) do n=n+1; tbl[n]=v end

    -- Remove duplicates from tbl and output clean res
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
    local tbl_out = {}
    if #res > 100 then
      local start_at = #res - 100
      for i = start_at+1, #res, 1 do
        table.insert(tbl_out, res[i])
      end
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
