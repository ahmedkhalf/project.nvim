-- Inspiration from:
-- https://github.com/nvim-telescope/telescope-project.nvim

local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  return
end

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local telescope_config = require("telescope.config").values
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local builtin = require("telescope.builtin")
local entry_display = require("telescope.pickers.entry_display")

local history = require("project_nvim.utils.history")
local project = require("project_nvim.project")
local config = require("project_nvim.config")

----------
-- Actions
----------

local function change_working_directory(prompt_bufnr, prompt)
  local selected_entry = state.get_selected_entry(prompt_bufnr)
  if selected_entry == nil then
    actions.close(prompt_bufnr)
    return
  end
  local project_path = selected_entry.value
  if prompt == true then
    actions._close(prompt_bufnr, true)
  else
    actions.close(prompt_bufnr)
  end
  local cd_successful = project.set_pwd(project_path, "telescope")
  return project_path, cd_successful
end

local function find_project_files(prompt_bufnr)
  local project_path, cd_successful = change_working_directory(prompt_bufnr, true)
  local opt = { cwd = project_path, hidden = config.options.show_hidden }
  if cd_successful then
    builtin.find_files(opt)
  end
end

local function browse_project_files(prompt_bufnr)
  local project_path, cd_successful = change_working_directory(prompt_bufnr, true)
  local opt = { cwd = project_path, hidden = config.options.show_hidden }
  if cd_successful then
    builtin.file_browser(opt)
  end
end

local function search_in_project_files(prompt_bufnr)
  local project_path, cd_successful = change_working_directory(prompt_bufnr, true)
  local opt = { cwd = project_path, hidden = config.options.show_hidden }
  if cd_successful then
    builtin.live_grep(opt)
  end
end

local function recent_project_files(prompt_bufnr)
  local _, cd_successful = change_working_directory(prompt_bufnr, true)
  local opt = { cwd_only = true, hidden = config.options.show_hidden }
  if cd_successful then
    builtin.oldfiles(opt)
  end
end

---Main entrypoint for Telescope.
---@param opts table
local function projects(opts)
  opts = opts or {}

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 30 },
      { remaining = true },
    },
  })

  local function make_display(entry)
    return displayer({
      entry.name,
      { entry.value, "Comment" },
    })
  end

  local results = history.get_recent_projects()

  -- Reverse results
  for i = 1, math.floor(#results / 2) do
    results[i], results[#results - i + 1] = results[#results - i + 1], results[i]
  end

  pickers.new(opts, {
    prompt_title = "Recent Projects",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        local name = vim.fn.fnamemodify(entry, ":t")
        return {
          display = make_display,
          name = name,
          value = entry,
          ordinal = name .. " " .. entry,
        }
      end,
    }),
    previewer = false,
    sorter = telescope_config.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      map("n", "f", find_project_files)
      map("n", "b", browse_project_files)
      map("n", "s", search_in_project_files)
      map("n", "r", recent_project_files)
      map("n", "w", change_working_directory)

      map("i", "<c-f>", find_project_files)
      map("i", "<c-b>", browse_project_files)
      map("i", "<c-s>", search_in_project_files)
      map("i", "<c-r>", recent_project_files)
      map("i", "<c-w>", change_working_directory)

      local on_project_selected = function()
        find_project_files(prompt_bufnr)
      end
      actions.select_default:replace(on_project_selected)
      return true
    end,
  }):find()
end

return telescope.register_extension({
  exports = { projects = projects },
})
