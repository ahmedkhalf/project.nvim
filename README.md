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
    lua << EOF
    require("nvim-tree").setup({
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true
      },
    })
    EOF
    ```
    ```lua
    -- lua
    require("nvim-tree").setup({
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true
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

  -- Retain directory settings for buffer. Override detection method.
  -- If directory was changed, the buffer will retain the same directory
  enable_buffer_local_dir = false,

  -- Retain directory settings for window. Override detection method.
  -- All buffers opened on the window will retain the directory
  enable_window_local_dir = false,

  -- When set to false, you will get a message when project.nvim changes your
  -- directory.
  silent_chdir = true,

  -- What scope to change the directory, valid options are
  -- * global (default)
  -- * tab
  -- * win
  scope_chdir = 'global',

  -- Path where project.nvim will store the project history for use in
  -- telescope
  datapath = vim.fn.stdpath("data"),
}
```

Even if you are pleased with the defaults, please note that `setup {}` must be
called for the plugin to start.

### Pattern Matching

**project.nvim**'s pattern engine uses the same expressions as vim-rooter, but
for your convenience, I will copy paste them here:

To specify the root is a certain directory, prefix it with `=`.

```lua
patterns = { "=src" }
```

To specify the root has a certain directory or file (which may be a glob), just
give the name:

```lua
patterns = { ".git", "Makefile", "*.sln", "build/env.sh" }
```

To specify the root has a certain directory as an ancestor (useful for
excluding directories), prefix it with `^`:

```lua
patterns = { "^fixtures" }
```

To specify the root has a certain directory as its direct ancestor / parent
(useful when you put working projects in a common directory), prefix it with
`>`:

```lua
patterns = { ">Latex" }
```

To exclude a pattern, prefix it with `!`.

```lua
patterns = { "!.git/worktrees", "!=extras", "!^fixtures", "!build/env.sh" }
```

List your exclusions before the patterns you do want.

### CWD scope and Window/Buffer Local directories
By default project.nvim sets the CWD to root of the project as explained above.
The directory being set scope can be set to tab/global/ as controlled by scope_chdir.
Occasionally, it is desirable to have a certain buffer always start in a specific directory. If this is needed, **enable_buffer_local_dir** can help you with it. With this option set, when user changes the working directory using "cd" while editing a buffer, the buffer will always stay in that directory all the time. All other buffers will continue to use the default working directory.
Similarly, a given window could be pinned to always use same directory. Any bufferes opened in that that window will always be opened in that directory. This is useful when sometimes the user uses "gf" to open files relative to that directory. To enable this, use **enable_window_local_dir** option.
NOTE: If both options are enabled, buffer local directory will be used over if window local diretory setting.

### Telescope Integration

To enable telescope integration:
```lua
require('telescope').load_extension('projects')
```

#### Telescope Projects Picker
To use the projects picker
```lua
require'telescope'.extensions.projects.projects{}
```

#### Telescope mappings

**project.nvim** comes with the following mappings:

| Normal mode | Insert mode | Action                     |
| ----------- | ----------- | -------------------------- |
| f           | \<c-f\>     | find\_project\_files       |
| b           | \<c-b\>     | browse\_project\_files     |
| d           | \<c-d\>     | delete\_project            |
| s           | \<c-s\>     | search\_in\_project\_files |
| r           | \<c-r\>     | recent\_project\_files     |
| w           | \<c-w\>     | change\_working\_directory |

## API

Get a list of recent projects:

```lua
local project_nvim = require("project_nvim")
local recent_projects = project_nvim.get_recent_projects()

print(vim.inspect(recent_projects))
```

## 🤝 Contributing

- All pull requests are welcome.
- If you encounter bugs please open an issue.
