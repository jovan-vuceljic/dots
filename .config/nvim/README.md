# Neovim Configuration Setup

This Neovim configuration is built on top of [NvChad](https://nvchad.com/), a popular Neovim framework designed for speed and aesthetics. It uses [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager.

## Core Components

- **Framework**: [NvChad](https://nvchad.com/) (v2.5)
- **Plugin Manager**: `lazy.nvim`
- **Theme Engine**: `base46` (integrated with NvChad)
- **Keybindings**: Custom mappings are defined in `lua/mappings.lua`.
- **Options**: Base options are inherited from NvChad, with customizations in `lua/options.lua`.

## Installed Plugins & Features

The configuration includes several key plugins and features:

### Development Tools
- **LSP (Language Server Protocol)**: Configured via `nvim-lspconfig`. Note that you must install the actual language servers using [Mason.nvim](https://github.com/williamboman/mason.nvim).
- **Formatting**: Uses `conform.nvim` for code formatting (configured in `lua/configs/conform.lua`).
- **Treesitter**: Provides advanced syntax highlighting and code folding (configured in `lua/plugins/init.lua`).
- **Telescope**: Powerful fuzzy finder for files, text, and LSP symbols.

### UI & Productivity
- **Snacks.nvim**: A collection of useful utilities including:
    - `explorer`: File explorer.
    - `indent`: Indent guides (replaces `indent-blankline.nvim` to avoid duplication).
    - `picker`: Fast picker for various tasks.
    - `notifier`: Improved notification system.
    - `words`: Word count and related features.
- **Render Markdown**: Enhances the appearance of Markdown files in the buffer (`lua/configs/render-markdown.lua`).

## Maintenance & Package Management

### Managing Plugins (lazy.nvim)
To update your installed Neovim plugins:
1. Open Neovim.
2. Run `:Lazy` to open the plugin manager UI.
3. Press `U` to check for updates and `u` to update everything.

### Managing LSPs & Tools (Mason.nvim)
While plugins are managed by `lazy.nvim`, the actual language servers, debuggers, and formatters are managed by **Mason**.
1. Open Neovim.
2. Run `:Mason` to open the Mason UI.
3. Use the UI to install or update your desired LSPs (e.g., `ts_ls`, `html`, `cssls`), linters, or formatters.

### Managing Syntax Highlighting (Treesitter)
To ensure all language parsers are installed for proper syntax highlighting:
1. Open Neovim.
2. Run `:TSUpdate` (or `:TSInstall <language>` for a specific one).

## Custom Keybindings

Some notable custom mappings (defined in `lua/mappings.lua`):

| Mapping | Action | Description |
|---------|--------|-------------|
| `gd` | `vim.lsp.buf.definition` | Go to definition |
| `gD` | `Telescope lsp_definitions` | Go to definitions (Telescope) |
| `grr` | `Telescope lsp_references` | Go to references (Telescope) |
| `<leader>da` | `vim.lsp.buf.code_action()` | Code actions |
| `<leader>dh` | `vim.diagnostic.open_float()` | Show diagnostics in float |
| `<leader>dj` | `vim.diagnostic.jump` | Go to next diagnostic |
| `<leader>dk` | `vim.diagnostic.jump` | Go to previous diagnostic |
| `<leader>fr` | `Telescope resume` | Resume last Telescope search |
| `<leader>fs` | `Telescope grep_string` | Find selected string |
| `<leader>fk` | `Telescope keymaps` | Find keymaps |
| `<leader>fd` | `Telescope diagnostics` | Search diagnostics |

**Improved Deletion/Change:**
- `x` (in Normal/Visual mode): Deletes a character without yanking it to the register.
- `c` (in Normal/Visual mode): Changes text without yanking it to the register.

## Directory Structure

```text
.
├── init.lua                # Entry point: bootstraps lazy.nvim and loads config
├── lazy-lock.json          # Lockfile for lazy.nvim
└── lua/
    ├── chadrc.lua          # NvChad configuration
    ├── configs/            # Plugin-specific configurations
    │   ├── conform.lua
    │   ├── lazy.lua
    │   ├── lspconfig.lua
    │   └── render-markdown.lua
    ├── mappings.lua        # Custom keybindings
    ├── options.lua         # Custom Neovim options
    └── plugins/
        └── init.lua        # Plugin definitions and setup
```

## Installation

1. Ensure you have [Neovim](https://neovim.io/) (latest stable or nightly) installed.
2. Clone this repository to your Neovim configuration directory (usually `~/.config/nvim`).
3. Open Neovim. `lazy.nvim` will automatically bootstrap and install all required plugins.
4. **Important**: After the initial plugin installation, run `:MasonInstall <server_name>` (or use the `:Mason` UI) to install the language servers required for your workflow.
5. Restart Neovim after the initial installation completes.
