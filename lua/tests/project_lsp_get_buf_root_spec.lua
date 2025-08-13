local eq = assert.are.same
local busted = require('plenary/busted')

local lsp_get_buf_root = require("project_nvim.project")._lsp_get_buf_root

describe('M._get_buf_root()):', function()
  it("testing M._get_buf_root() returns correct buf_root for embedded projects", function()
    local outter_project = "/Users/kkrime/outter_project"
    local inner_project = "/Users/kkrime/outter_project/inner_project"

    local client = {}
    client["workspace_folders"] = { { uri = "file://" .. outter_project }, { uri = "file://" .. inner_project } }

    -- file in project root
    local buf_name = outter_project .. "/main.file"
    local res = lsp_get_buf_root(client, buf_name)
    eq(res, outter_project)

    -- file in project root
    buf_name = inner_project .. "/main.file"
    res = lsp_get_buf_root(client, buf_name)
    eq(res, inner_project)

    -- file deep inside the project
    buf_name = outter_project .. "/folder/folder/helper.file"
    res = lsp_get_buf_root(client, buf_name)
    eq(res, outter_project)

    -- file deep inside the project
    buf_name = inner_project .. "/folder/folder/helper.file"
    res = lsp_get_buf_root(client, buf_name)
    eq(res, inner_project)
  end)
end)
