return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    opts = {
      ensure_installed = {
        "vim",
        "vimdoc",
        "lua",
        "luadoc",
        "printf",
        "html",
        "css",
        "typescript",
        "javascript",
        "markdown",
        "scss",
        "svelte",
        "typst",
        "vue",
        "regex",
      },
    },
    -- On the main branch nothing acts on `ensure_installed` at startup: setup() takes only
    -- install_dir, and NvChad's :TSInstallAll (which does read this list off the lazy spec)
    -- only runs from `build`, i.e. when the plugin is installed or updated. So a language
    -- added here stayed uninstalled until the next rebuild — 9 of these 15 were missing,
    -- silently falling back to regex highlighting. Install whatever is absent, once, here.
    config = function(_, opts)
      local ts = require "nvim-treesitter"
      ts.setup()

      local have = {}
      for _, lang in ipairs(ts.get_installed()) do
        have[lang] = true
      end
      local missing = vim.tbl_filter(function(lang)
        return not have[lang]
      end, opts.ensure_installed or {})
      if #missing > 0 then
        ts.install(missing) -- async; highlighting picks each up as it lands
      end
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "gitcommit" },
    opts = function()
      return require "configs.render-markdown"
    end,
  },

  -- snacks.indent (below) draws the indent guides — disable NvChad's indent-blankline
  -- so they don't render doubled
  { "lukas-reineke/indent-blankline.nvim", enabled = false },

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = false },
      dashboard = { enabled = false },
      explorer = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      picker = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
    },
  },

  -- These are some examples, uncomment them if you want to see them work!
  --
  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
  --
}
