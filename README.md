# 🗃️ project.nvim

**project.nvim** is an all in one neovim plugin written in lua that provides
superior project management.

![Telescope Integration](https://user-images.githubusercontent.com/36672196/129409509-62340f10-4dd0-4c1a-9252-8bfedf2a9945.png)

## ⚡ Requirements

- Neovim >= 0.5.0

## ✨ Features

- Automagically cd to project directory using nvim lsp
  - Dependency free, does not rely on lspconfig
- If no lsp then uses pattern matching to cd to root directory
- Telescope integration `:Telescope projects`
  - Access your recently opened projects from telescope!
  - Asynchronous file io so it will not slow down vim when reading the history
    file on startup.
- ~~Nvim-tree.lua support/integration~~
  - Please add the following to your config instead:
    ```vim
    " Vim Script
    let g:nvim_tree_respect_buf_cwd = 1
    
    lua << EOF
    require("nvim-tree").setup({
      update_cwd = true,
      update_focused_file = {
        enable = true,
        update_cwd = true
      },
    EOF
    ```
    ```lua
    -- lua
    vim.g.nvim_tree_respect_buf_cwd = 1
    
    require("nvim-tree").setup({
      update_cwd = true,
      update_focused_file = {
        enable = true,
        update_cwd = true
      },
    })
    ```

## 📦 Installation

Install the plugin with your preferred package manager:

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
" Vim Script
Plug 'ahmedkhalf/project.nvim'

lua << EOF
  require("project_nvim").setup {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  }
EOF
```

### [packer](https://github.com/wbthomason/packer.nvim)

```lua
-- Lua
use {
  "ahmedkhalf/project.nvim",
  config = function()
    require("project_nvim").setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  end
}
```

## ⚙️ Configuration

**project.nvim** comes with the following defaults:

```lua
{
  -- Manual mode doesn't automatically change your root directory, so you have
  -- the option to manually do so using `:ProjectRoot` command.
  manual_mode = false,

  -- Methods of detecting the root directory. **"lsp"** uses the native neovim
  -- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
  -- order matters: if one is not detected, the other is used as fallback. You
  -- can also delete or rearangne the detection methods.
  detection_methods = { "lsp", "pattern" },

  -- All the patterns used to detect root dir, when **"pattern"** is in
  -- detection_methods
  patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json" },

  -- Table of lsp clients to ignore by name
  -- eg: { "efm", ... }
  ignore_lsp = {},

  -- Don't calculate root dir on specific directories
  -- Ex: { "~/.cargo/*", ... }
  exclude_dirs = {},

  -- Show hidden files in telescope
  show_hidden = false,

  -- When set to false, you will get a message when project.nvim changes your
  -- directory.
  silent_chdir = true,

  -- Path where project.nvim will store the project history for use in
  -- telescope
  datapath = vim.fn.stdpath("data"),

  -- Function to call when you select a project from telecope
  -- Accepts:
  --    "find_project_files"        : call 'Telescope find_files' on project
  --    "browse_project_files"      : call 'Telescope file_browser' on project
  --    "search_in_project_files"   : call 'Telescope live_grep' on project
  --    "recent_project_files"      : call 'Telescope oldfiles' on project
  --    "change_working_directory"  : just change the directory
  -- Note: All will change the directory regardless
  telescope_on_project_selected = "find_project_files"
}
```

Even if you are pleased with the defaults, please note that `setup {}` must be
called for the plugin to start.

### Telescope Integration

To enable telescope integration:
```lua
require('telescope').load_extension('projects')
```

### Pattern Matching

**project.nvim**'s pattern engine uses the same expressions as vim-rooter, but
for your convenience, I will copy paste them here:

To specify the root is a certain directory, prefix it with `=`.

```lua
detection_methods = { "=src" }
```

To specify the root has a certain directory or file (which may be a glob), just
give the name:

```lua
detection_methods = { ".git", "Makefile", "*.sln", "build/env.sh" }
```

To specify the root has a certain directory as an ancestor (useful for
excluding directories), prefix it with `^`:

```lua
detection_methods = { "^fixtures" }
```

To specify the root has a certain directory as its direct ancestor / parent
(useful when you put working projects in a common directory), prefix it with
`>`:

```lua
detection_methods = { ">Latex" }
```

To exclude a pattern, prefix it with `!`.

```lua
detection_methods = { "!.git/worktrees", "!=extras", "!^fixtures", "!build/env.sh" }
```

List your exclusions before the patterns you do want.

## 🤝 Contributing

- All pull requests are welcome.
- If you encounter bugs please open an issue.
