-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig

local M = {
  base46 = {
    theme = "onedark",
    transparency = true,
    lsp = { signature = true },
    hl_override = {
      NvimTreeGitDirty = {
        fg = "#DBA55D",
      },
    },
    -- Comment = { italic = true },
    -- ["@comment"] = { italic = true },
  },

  nvdash = {
    load_on_startup = false,
    -- buttons = {
    --   { txt = "  Find File", keys = "Spc f f", cmd = "Telescope find_files custom" },
    --   { txt = "  Recent Files", keys = "Spc f o", cmd = "Telescope oldfiles" },
    --   -- more... check nvconfig.lua file for full list of buttons
    -- },
  },

  ui = {
    -- lazyload it when there are 1+ buffers
    tabufline = {
      enabled = true,
      lazyload = true,
      order = { "treeOffset", "buffers", "tabs", "btns" },
      modules = nil,
      bufwidth = 21,
      transparency = true,
    },
  },

  term = {
    base46_colors = true,
    winopts = { number = false },
    sizes = { sp = 0.5, vsp = 0.2, ["bo sp"] = 0.3, ["bo vsp"] = 0.2 },
    float = {
      relative = "editor",
      row = 0.05,
      col = 0.05,
      width = 0.9,
      height = 0.8,
      border = "single",
    },
  },
}

return M
