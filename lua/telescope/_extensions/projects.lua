local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  return
end

local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local config = require("telescope.config").values
local actions = require "telescope.actions"
local entry_display = require "telescope.pickers.entry_display"

local util = require("project_nvim.util")

---Main entrypoint for Telescope.
---@param opts table
local function projects(opts)
  opts = opts or {}

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 30 },
      { remaining = true },
    },
  }

  local function make_display(entry)
    return displayer {
      entry.name,
      { entry.value, "Comment" },
    }
  end

  local results = util.get_recent_projects()

  pickers.new(opts, {
    prompt_title = "Recent Projects",
    finder = finders.new_table {
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
    },
    previewer = false,
    sorter = config.generic_sorter(opts),
    -- attach_mappings = function()
    --   actions.select_default:replace(smart_url_opener(state))
    --   return true
    -- end,
  }):find()
end

return telescope.register_extension {
  exports = { projects = projects },
}
