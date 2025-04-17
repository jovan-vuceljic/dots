vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

----- custom config -----

if vim.g.neovide then
  vim.g.neovide_transparency = 0.7
  vim.g.neovide_scale_factor = 0.7
  vim.g.neovide_window_blurred = true
  vim.g.neovide_floating_blur_amount_x = 1.0
  vim.g.neovide_floating_blur_amount_y = 1.0
  vim.g.neovide_floating_shadow = true
  vim.g.neovide_floating_z_height = 0
  vim.g.neovide_hide_mouse_when_typing = true
  vim.g.neovide_padding_top = 15
  vim.g.neovide_padding_right = 5
  vim.g.neovide_padding_left = 5
  -- vim.g.neovide_fullscreen = true
  -- vim.g.neovide_padding_bottom = 0
  -- vim.g.neovide_light_radius = 5
  -- vim.g.neovide_show_border = false 
  -- vim.g.neovide_light_angle_degrees = 45
end

vim.opt.relativenumber = true
vim.opt.wrap = false

----- end of custom -----


-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)
